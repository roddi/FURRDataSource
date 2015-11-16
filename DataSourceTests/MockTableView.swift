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

    var insertionRowIndexPaths: [NSIndexPath] = []
    var deletionRowIndexPaths: [NSIndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    override func insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionSectionIndexSet.addIndexes(sections)
        if let callback = insertSectionsCallback {
            callback(indexSet: sections)
        }
    }

    override func deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionSectionIndexSet.addIndexes(sections)
        if let callback = deleteSectionsCallback {
            callback(indexSet: sections)
        }
    }

    override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }

    override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }

}
