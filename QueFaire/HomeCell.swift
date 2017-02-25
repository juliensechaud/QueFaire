//
//  HomeCell.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 10/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import UIKit

class HomeCell: UITableViewCell {
    
    @IBOutlet weak var sImageView: UIImageView!
    @IBOutlet weak var cacheView: UIView!
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.sImageView.alpha = 0.8
        } else {
            self.sImageView.alpha = 0.6
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.sImageView.alpha = 0.8
        } else {
            self.sImageView.alpha = 0.6
        }
    }
}
