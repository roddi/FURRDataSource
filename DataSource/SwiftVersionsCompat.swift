//
//  SwiftVersionsCompat.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 05.07.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import UIKit

enum CompatTableViewCellEditingStyle {
    case delete
    case insert
    case none
}


#if swift(>=3.0)
    public typealias IndexPathway = IndexPath

    extension CompatTableViewCellEditingStyle {
        init(editingStyle: UITableViewCellEditingStyle) {
            switch editingStyle {
            case .delete:
                self = .delete
            case .insert:
                self = .insert
            case .none:
                self = .none
            }
        }
    }

#else
    public typealias IndexPathway = NSIndexPath

    extension CompatTableViewCellEditingStyle {
        init(editingStyle: UITableViewCellEditingStyle) {
            switch editingStyle {
            case .Delete:
                self = .delete
            case .Insert:
                self = .insert
            case .None:
                self = .none
            }
        }
    }
#endif
