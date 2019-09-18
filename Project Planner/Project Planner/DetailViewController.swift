//
//  DetailViewController.swift
//  Project Planner
//
//  Created by Shakil on 02/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UITableViewController, NSFetchedResultsControllerDelegate {
        
    var managedObjectContext: NSManagedObjectContext? = nil
    var tasks: [Task]?
    var project: Project?
    var appDelegate: AppDelegate?
    
    @IBOutlet weak var projectDetailView: UIView!
    @IBOutlet weak var projectTitleLabel: UILabel!
    @IBOutlet weak var projectNotesLabel: UILabel!
    @IBOutlet weak var projectProgressLabel: UILabel!
    @IBOutlet weak var projectDaysLeftLabel: UILabel!
    
    @IBOutlet weak var projectProgressLeftView: ProgressBarView! {
        didSet {
            projectProgressLeftView.trackColor = .gray
        }
    }
    @IBOutlet weak var projectProgressView: ProgressBarView! {
        didSet {
            projectProgressView.trackColor = .gray
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductDeleteNotification(_:)),
                                               name: NSNotification.Name(rawValue: "Project Deleted"),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProductEditNotification(_:)),
                                               name: NSNotification.Name(rawValue: "Project Edited"),
                                               object: nil)
        
        if let _ = project {
            let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewTaskTapped(_:)))
            navigationItem.rightBarButtonItem = addButton
        }
        
        if var projectTasks = project?.task?.allObjects as? [Task] {
            projectTasks.sort { $0.endDate ?? Date() < $1.endDate ?? Date() }
            tasks = projectTasks
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        self.appDelegate = appDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let project = project {
            setupProjectDetails(project)
        } else {
            projectDetailView.frame = .zero
            projectDetailView.removeFromSuperview()
        }
    }
    
    fileprivate func setupProjectDetails(_ project: Project) {
        var priority = "Low"
        switch project.priority {
        case 1:
            priority = "Medium"
        case 2:
            priority = "High"
        default:
            break
        }
        projectTitleLabel.text = (project.name ?? "") + " - Priority - " + priority
        projectNotesLabel.text = project.notes
        
        var projectProgress: Float = 0.0
        if let tasks = project.task {
            for task in tasks {
                projectProgress += (task as? Task)?.progress ?? 0.0
            }
            if tasks.count > 0 {
                projectProgress = projectProgress / Float(tasks.count)
            }
        }
        
        projectProgressView.progressValue = CGFloat(projectProgress)
        projectProgressLabel.text = "\(Int(projectProgress.rounded()))%" + " complete"
        
        if let daysRemaining = project.endDate?.daysFromDate(Date()), let totalDays = project.endDate?.daysFromDate(project.startDate ?? Date()) {
            projectProgressLeftView.progressValue = CGFloat((Float(daysRemaining) / Float(totalDays)) * 100)
            projectDaysLeftLabel.text = "\(daysRemaining)" + " days remaining"
        }
        
        projectProgressView.barColorForValue = { value in
            switch value {
            case 0..<20:
                return UIColor.red
            case 20..<60:
                return UIColor.orange
            case 60..<80:
                return UIColor.yellow
            default:
                return UIColor.green
            }
        }
        
        projectDetailView.layer.borderColor = UIColor.lightGray.cgColor
        projectDetailView.layer.borderWidth = 0.5
    }
    
    @objc
    func addNewTaskTapped(_ sender: UIBarButtonItem) {
        if let taskAddEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "TaskAddEditViewController") as? TaskAddEditViewController {
            taskAddEditViewController.project = self.project
            taskAddEditViewController.context = self.managedObjectContext

            taskAddEditViewController.modalPresentationStyle = .popover
            
            if let popoverPresentationController = taskAddEditViewController.popoverPresentationController {
                popoverPresentationController.delegate = self
                popoverPresentationController.barButtonItem = sender
            }
            self.present(taskAddEditViewController, animated: true, completion: nil)
            
            taskAddEditViewController.taskSaved = {
                if var projectTasks = self.project?.task?.allObjects as? [Task] {
                    projectTasks.sort { $0.endDate ?? Date() < $1.endDate ?? Date() }
                    self.tasks = projectTasks
                }
                
                self.tableView.reloadData()
                if let project = self.project {
                    self.setupProjectDetails(project)
                }
            }
        }
    }
    
    @objc func handleProductDeleteNotification(_ notification: Notification) {
        guard let _ = notification.object as? Project else { return }
        
        projectDetailView.frame = .zero
        projectDetailView.removeFromSuperview()
        tableView.reloadData()
    }
    
    @objc func handleProductEditNotification(_ notification: Notification) {
        guard let project = notification.object as? Project else { return }
        
        self.project = project
        setupProjectDetails(project)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return project?.task?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskTableViewCell {
            if let task = tasks?[indexPath.row] {
                cell.taskNumberLabel.text = "Task \(indexPath.row + 1)."
                configureCell(cell, withTask: task)
            }
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            if let context = self.managedObjectContext, let task = self.tasks?[indexPath.row] {
                context.delete(task)
                self.tasks?.remove(at: indexPath.row)

                do {
                    try context.save()
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self.appDelegate?.deleteNotification(identifier: task.identifier ?? "")
                    
                    if let project = self.project {
                        self.setupProjectDetails(project)
                    }
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
        
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { (action, indexPath) in
            if let taskAddEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "TaskAddEditViewController") as? TaskAddEditViewController {
                taskAddEditViewController.context = self.managedObjectContext
                taskAddEditViewController.task = self.tasks?[indexPath.row]
                taskAddEditViewController.project = self.project
                
                taskAddEditViewController.modalPresentationStyle = .popover
                
                if let popoverPresentationController = taskAddEditViewController.popoverPresentationController {
                    popoverPresentationController.delegate = self
                    popoverPresentationController.sourceView = tableView.cellForRow(at: indexPath)
                    popoverPresentationController.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
                }
                self.present(taskAddEditViewController, animated: true, completion: nil)
                
                taskAddEditViewController.taskSaved = {
                    if var projectTasks = self.project?.task?.allObjects as? [Task] {
                        projectTasks.sort { $0.endDate ?? Date() < $1.endDate ?? Date() }
                        self.tasks = projectTasks
                    }
                    
                    self.tableView.reloadData()
                    if let project = self.project {
                        self.setupProjectDetails(project)
                    }
                }
            }
        }
        
        edit.backgroundColor = .gray
        
        return [edit, delete]
    }
    
    func configureCell(_ cell: TaskTableViewCell, withTask task: Task) {
        cell.taskTitleLabel.text = task.name?.description
        cell.taskNotesLabel.text = task.notes?.description
        if let endDate = task.endDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MMM-yyyy"
            cell.taskDueDateLabel.text = "- Due: " + formatter.string(from: endDate)
        }
        cell.progressBar.progressValue = CGFloat(task.progress)
        cell.sliderView.value = (task.progress / 100)
        
        cell.progressBar.barColorForValue = { value in
            switch value {
            case 0..<20:
                return UIColor.red
            case 20..<60:
                return UIColor.orange
            case 60..<80:
                return UIColor.yellow
            default:
                return UIColor.green
            }
        }
        
        switch task.progress {
        case 0..<20:
            cell.sliderView.minimumTrackTintColor = .red
        case 20..<60:
            cell.sliderView.minimumTrackTintColor = .orange
        case 60..<80:
            cell.sliderView.minimumTrackTintColor = .yellow
        default:
            cell.sliderView.minimumTrackTintColor = .green
        }
        
        cell.taskProgressChanged = { progressValue in
            task.progress = progressValue
            do {
                try self.managedObjectContext?.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            if let project = self.project {
                self.setupProjectDetails(project)
            }
        }
    }
    
}

extension DetailViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .popover
    }
}
