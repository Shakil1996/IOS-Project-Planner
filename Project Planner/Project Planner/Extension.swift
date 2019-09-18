//
//  Extension.swift
//  Project Planner
//
//  Created by Shakil on 17/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import Foundation
import UIKit
import EventKit

extension UIViewController {
    
    func presentAlert(alertTitle: String, alertMessage: String, actionTitle: String, addCancelButton: Bool = false, actionHandler:((UIAlertAction) -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: actionTitle, style: .default, handler: actionHandler)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        if addCancelButton {
            alertController.addAction(cancelAction)
        }
        present(alertController, animated: true, completion: nil)
    }
    
    func addEventToCalendar(title: String, description: String?, endDate: Date, completion: ((_ success: Bool, _ error: NSError?, _ event: EKEvent?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async { () -> Void in
            let eventStore = EKEventStore()
            
            eventStore.requestAccess(to: .event, completion: { (granted, error) in
                if (granted) && (error == nil) {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = title
                    event.startDate = endDate
                    event.endDate = endDate
                    event.isAllDay = true
                    event.notes = description
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    do {
                        try eventStore.save(event, span: .thisEvent)
                    } catch let e as NSError {
                        completion?(false, e, nil)
                        return
                    }
                    completion?(true, nil, event)
                } else {
                    completion?(false, error as NSError?, nil)
                }
            })
        }
    }
    
    func removeEventFromCalender(identifier: String, completion: ((_ success: Bool, _ error: NSError?) -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async { () -> Void in
            let eventStore = EKEventStore()
            
            eventStore.requestAccess(to: .event, completion: { (granted, error) in
                if (granted) && (error == nil) {
                    if let event = eventStore.event(withIdentifier: identifier) {
                        do {
                            try eventStore.remove(event, span: .thisEvent, commit: true)
                        } catch let e as NSError {
                            completion?(false, e)
                            return
                        }
                    }
                    completion?(true, nil)
                } else {
                    completion?(false, error as NSError?)
                }
            })
        }
    }
}

extension Date {
    func daysFromDate(_ date: Date) -> Int {
        return abs(Calendar.current.dateComponents([.day], from: self, to: date).day!)
    }
}

extension Comparable {
    func clamped(lowerBound: Self, upperBound: Self) -> Self {
        return min(max(self, lowerBound), upperBound)
    }
}


