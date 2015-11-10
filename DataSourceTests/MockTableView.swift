//
//  MockTableView.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 19.10.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit

class MockTableView: UITableView {

    var insertRowsCallback: ((indexPaths: [NSIndexPath]) -> Void)?
    var deleteRowsCallback: ((indexPaths: [NSIndexPath]) -> Void)?

    var insertSectionsCallback: ((indexSet: NSIndexSet) -> Void)?
    var deleteSectionsCallback: ((indexSet: NSIndexSet) -> Void)?

    var insertionIndexPaths: [NSIndexPath] = []
    var deletionIndexPaths: [NSIndexPath] = []

    var insertionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    override func insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionIndexSet.addIndexes(sections)
        if let callback = insertSectionsCallback {
            callback(indexSet: sections)
        }
    }

    override func deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionIndexSet.addIndexes(sections)
        if let callback = deleteSectionsCallback {
            callback(indexSet: sections)
        }
    }

    override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }

    override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }

}
