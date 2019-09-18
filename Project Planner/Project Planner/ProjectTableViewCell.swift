//
//  ProjectTableViewCell.swift
//  Project Planner
//
//  Created by Shakil on 05/05/19.
//  Copyright © 2019 shakil. All rights reserved.
//

import UIKit

class ProjectTableViewCell: UITableViewCell {

    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var projectDueDateLabel: UILabel!
    @IBOutlet weak var projectNotesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
