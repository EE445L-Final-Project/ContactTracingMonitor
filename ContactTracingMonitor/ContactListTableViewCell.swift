//
//  ContactListTableViewCell.swift
//  ContactTracingMonitor
//
//  Created by apple on 11/26/20.
//  Copyright © 2020 utexas. All rights reserved.
//

import UIKit

class ContactListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var contactInfoLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
