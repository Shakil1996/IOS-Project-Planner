//
//  TaskTableViewCell.swift
//  Project Planner
//
//  Created by Shakil on 05/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var taskNumberLabel: UILabel!
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var taskDueDateLabel: UILabel!
    @IBOutlet weak var taskNotesLabel: UILabel!
    @IBOutlet weak var sliderView: UISlider! {
        didSet {
            sliderView.maximumTrackTintColor = .gray
        }
    }
    @IBOutlet weak var progressBar: ProgressBarView! {
        didSet {
            progressBar.trackColor = .gray
        }
    }
    
    var taskProgressChanged: ((Float) -> Void)?
    
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
    @IBAction func changeSliderValue(_ sender: UISlider) {
        progressBar.progressValue = CGFloat(sender.value * 100)
        
        progressBar.barColorForValue = { value in
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
        
        switch sender.value * 100 {
            case 0..<20:
                sliderView.minimumTrackTintColor = .red
            case 20..<60:
                sliderView.minimumTrackTintColor = .orange
            case 60..<80:
                sliderView.minimumTrackTintColor = .yellow
            default:
                sliderView.minimumTrackTintColor = .green
        }
        
        taskProgressChanged?(sender.value * 100)
    }
}
