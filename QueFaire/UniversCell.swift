//
//  UniversCell.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 10/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit

class UniversCell: UITableViewCell {
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if highlighted {
            self.textLabel?.font = UIFont(name: "Avenir-Heavy", size: 14)
        } else {
            self.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        if selected {
            self.textLabel?.font = UIFont(name: "Avenir-Heavy", size: 14)
        } else {
            self.textLabel?.font = UIFont(name: "Avenir-Light", size: 14)
        }
    }

}
