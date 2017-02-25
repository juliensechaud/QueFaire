//
//  NSStringExtensions.swift
//  QueFaire
//
//  Created by Julien SECHAUD on 10/07/2016.
//  Copyright © 2016 Moana et Archibald. All rights reserved.
//

import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).uppercased()
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
