//
//  ProjectAddEditViewController.swift
//  Project Planner
//
//  Created by Shakil on 04/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import UIKit
import CoreData

class ProjectAddEditViewController: UIViewController {

    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var projectNotesTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            datePicker.minimumDate = Date()
        }
    }
    @IBOutlet weak var prioritySegment: UISegmentedControl! {
        didSet {
            let font = UIFont.systemFont(ofSize: 20)
            prioritySegment.setTitleTextAttributes([NSAttributedString.Key.font: font],
                                                    for: .normal)
        }
    }
    @IBOutlet weak var addToCalenderSwitch: UISwitch!
    
    var context: NSManagedObjectContext!
    var project: Project?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.preferredContentSize = CGSize(width: view.frame.width/2, height: view.frame.height - 200)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let project = project {
            projectNameTextField.text = project.name
            projectNotesTextField.text = project.notes
            prioritySegment.selectedSegmentIndex = Int(project.priority)
            addToCalenderSwitch.setOn(project.addToCalender, animated: true)
            if let date = project.endDate {
                datePicker.setDate(date, animated: true)
            }
        }
    }
    
    fileprivate func saveProject() {
        // Save the context.
        do {
            try context.save()
            self.dismiss(animated: true)
            if let project = project {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "Project Edited"), object: project)
            }
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        let projectName = projectNameTextField.text ?? ""
        let projectNotes = projectNotesTextField.text ?? ""
        let endDate = Calendar.current.dateComponents([.day, .month, .year], from: datePicker.date)
        let priority = prioritySegment.selectedSegmentIndex
        let addToCalender = addToCalenderSwitch.isOn
        
        if projectName.isEmpty || projectNotes.isEmpty {
            presentAlert(alertTitle: "Blank Project name or Project notes!", alertMessage: "Project name and Project notes cannot be blank", actionTitle: "OK")
            
            return
        }
        
        if let project = project {
            project.name = projectName
            project.notes = projectNotes
            project.endDate = Calendar(identifier: .gregorian).date(from: endDate)?.addingTimeInterval((60 * 60 * 24) - 1)
            project.priority = Int16(priority)
            project.addToCalender = addToCalender
            
            if addToCalender {
                if let eventIdentifier = project.eventId {
                    self.removeEventFromCalender(identifier: eventIdentifier) { (success, error) in
                        if success {
                            self.addEventToCalendar(title: project.name ?? "", description: project.notes, endDate: project.endDate ?? Date()) { (success, error, event) in
                                if success {
                                    print("Event added to calender")
                                    project.eventId = event?.eventIdentifier
                                } else {
                                    self.presentAlert(alertTitle: "Error!", alertMessage: error?.description ?? "", actionTitle: "OK")
                                }
                            }
                        } else {
                            self.presentAlert(alertTitle: "Error!", alertMessage: error?.description ?? "", actionTitle: "OK")
                        }
                    }
                } else {
                    self.addEventToCalendar(title: project.name ?? "", description: project.notes, endDate: project.endDate ?? Date()) { (success, error, event) in
                        if success {
                            print("Event added to calender")
                            project.eventId = event?.eventIdentifier
                        } else {
                            self.presentAlert(alertTitle: "Error!", alertMessage: error?.description ?? "", actionTitle: "OK")
                        }
                    }
                }
            } else {
                if let eventIdentifier = project.eventId {
                    self.removeEventFromCalender(identifier: eventIdentifier)
                }
            }
            
            saveProject()
        } else {
            let project = Project(context: context)
            
            // If appropriate, configure the new managed object.
            project.name = projectName
            project.notes = projectNotes
            project.endDate = Calendar(identifier: .gregorian).date(from: endDate)?.addingTimeInterval((60 * 60 * 24) - 1)
            project.priority = Int16(priority)
            project.addToCalender = addToCalender
            project.startDate = Date()
            
            if addToCalender {
                addEventToCalendar(title: project.name ?? "", description: project.notes, endDate: project.endDate ?? Date()) { (success, error, event) in
                    if success {
                        print("Event added to calender")
                        project.eventId = event?.eventIdentifier
                    } else {
                        self.presentAlert(alertTitle: "Error!", alertMessage: error?.description ?? "", actionTitle: "OK")
                    }
                }
            }
            
            saveProject()
        }
    }
}
