//
//  Rusher.swift
//  RushingCells
//
//  Created by Deecke,Roddi on 26.08.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit

class Rusher: DataItem {
    let identifier: String
    var date: NSDate

    init(inIdentifier: String) {
        self.identifier = inIdentifier
        self.date = NSDate.distantPast()
    }
}

extension Rusher : Equatable {

}

func == (lhs: Rusher, rhs: Rusher) -> Bool {
    return lhs.identifier == rhs.identifier
}
