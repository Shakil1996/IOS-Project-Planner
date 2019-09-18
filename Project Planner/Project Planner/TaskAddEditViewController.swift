//
//  TaskAddEditViewController.swift
//  Project Planner
//
//  Created by Shakil on 04/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class TaskAddEditViewController: UIViewController {

    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var taskNotesTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            datePicker.minimumDate = Date()
        }
    }
    @IBOutlet weak var addNotificationSwitch: UISwitch!
    
    var context: NSManagedObjectContext!
    var task: Task?
    var project: Project?
    var taskSaved: (() -> Void)?
    var appDelegate: AppDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.preferredContentSize = CGSize(width: view.frame.width/2, height: view.frame.height - 200)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        self.appDelegate = appDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let task = task {
            taskNameTextField.text = task.name
            taskNotesTextField.text = task.notes
            addNotificationSwitch.setOn(task.addNotification, animated: true)
            if let date = task.endDate {
                datePicker.setDate(date, animated: true)
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        let taskName = taskNameTextField.text ?? ""
        let taskNotes = taskNotesTextField.text ?? ""
        let endDate = datePicker.date
        let addNotification = addNotificationSwitch.isOn
        let identifier = "TASKREMINDER_" + String(arc4random_uniform(100000))
        
        if taskName.isEmpty || taskNotes.isEmpty {
            presentAlert(alertTitle: "Blank Task name or Task notes!", alertMessage: "Task name and Task notes cannot be blank", actionTitle: "OK")
            
            return
        }
        
        if let task = task {
            task.name = taskName
            task.notes = taskNotes
            task.endDate = endDate
            task.addNotification = addNotification
        } else {
            let task = Task(context: context)
            
            task.name = taskName
            task.notes = taskNotes
            task.endDate = endDate
            task.addNotification = addNotification
            task.identifier = identifier
            task.progress = 0.0
            if let taskproject = project {
                task.project = taskproject
            }
        }
        
        // Save the context.
        do {
            try context.save()
            if let task = task {
                if task.addNotification {
                    appDelegate?.deleteNotification(identifier: task.identifier ?? "")
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd-MMM-yyyy"
                    let components = Calendar.current.dateComponents([.day, .month, .year], from: endDate.addingTimeInterval(24 * 60 * 60))
                    appDelegate?.createNotification(title: "Task: \(taskName)", subtitle: "", body: "This task has passed its due date - \(formatter.string(from: endDate))", components: components, identifier: identifier)
                } else {
                    // handle case if notification was added earlier and now removed.
                    appDelegate?.deleteNotification(identifier: task.identifier ?? "")
                }
            } else {
                if addNotification {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd-MMM-yyyy"
                    let components = Calendar.current.dateComponents([.day, .month, .year], from: endDate.addingTimeInterval(24 * 60 * 60))
                    appDelegate?.createNotification(title: "Task: \(taskName)", subtitle: "", body: "This task has passed its due date - \(formatter.string(from: endDate))", components: components, identifier: identifier)
                }
            }
            self.dismiss(animated: true) {
                self.taskSaved?()
            }
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
}
