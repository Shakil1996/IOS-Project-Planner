//
//  MasterViewController.swift
//  Project Planner
//
//  Created by Shakil on 02/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    var appDelegate: AppDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewProjectTapped(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            detailViewController?.managedObjectContext = managedObjectContext
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        self.appDelegate = appDelegate
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func addNewProjectTapped(_ sender: UIBarButtonItem) {
        if let projectAddEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProjectAddEditViewController") as? ProjectAddEditViewController {
            projectAddEditViewController.context = self.fetchedResultsController.managedObjectContext
            
            projectAddEditViewController.modalPresentationStyle = .popover
            
            if let popoverPresentationController = projectAddEditViewController.popoverPresentationController {
                popoverPresentationController.delegate = self
                popoverPresentationController.barButtonItem = sender
            }
            self.present(projectAddEditViewController, animated: true, completion: nil)
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.project = object
                controller.managedObjectContext = managedObjectContext
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as? ProjectTableViewCell {
            let project = fetchedResultsController.object(at: indexPath)
            configureCell(cell, withProject: project)
            
            return cell
        } else {
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let context = fetchedResultsController.managedObjectContext
//            context.delete(fetchedResultsController.object(at: indexPath))
//
//            do {
//                try context.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let context = self.fetchedResultsController.managedObjectContext
            let project = self.fetchedResultsController.object(at: indexPath)
            context.delete(project)
            
            do {
                // delete project tasks
                if let tasks = project.task {
                    for task in tasks {
                        self.appDelegate?.deleteNotification(identifier: (task as? Task)?.identifier ?? "")
                    }
                }
                
                // delete project calender event
                if project.addToCalender {
                    if let eventIdentifier = project.eventId {
                        self.removeEventFromCalender(identifier: eventIdentifier)
                    }
                }
                
                try context.save()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Project Deleted"), object: project)
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            if let projectAddEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "ProjectAddEditViewController") as? ProjectAddEditViewController {
                projectAddEditViewController.context = self.fetchedResultsController.managedObjectContext
                projectAddEditViewController.project = self.fetchedResultsController.object(at: indexPath)
                
                projectAddEditViewController.modalPresentationStyle = .popover
                
                if let popoverPresentationController = projectAddEditViewController.popoverPresentationController {
                    popoverPresentationController.delegate = self
                    popoverPresentationController.sourceView = tableView.cellForRow(at: indexPath)
                    popoverPresentationController.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
                }
                self.present(projectAddEditViewController, animated: true, completion: nil)
            }
        }
        
        edit.backgroundColor = .gray

        return [edit, delete]
    }

    func configureCell(_ cell: ProjectTableViewCell, withProject project: Project) {
        cell.projectNameLabel.text = project.name?.description
        cell.projectNotesLabel.text = project.notes?.description
        if let endDate = project.endDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MMM-yyyy"
            cell.projectDueDateLabel.text = formatter.string(from: endDate)
        }
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Project> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "endDate", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController<Project>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!) as! ProjectTableViewCell, withProject: anObject as! Project)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!) as! ProjectTableViewCell, withProject: anObject as! Project)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}

extension MasterViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .popover
    }
}

