// swiftlint:disable line_length
//
//  MockTableView.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 19.10.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit
@testable import FURRDataSource

class MockTableView: UITableView {

    var insertRowsCallback: (([CompatIndexPath]) -> Void)?
    var deleteRowsCallback: (([CompatIndexPath]) -> Void)?
    var insertSectionsCallback: ((NSIndexSet) -> Void)?
    var deleteSectionsCallback: ((NSIndexSet) -> Void)?

    var insertionRowIndexPaths: [CompatIndexPath] = []
    var deletionRowIndexPaths: [CompatIndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    #if swift(>=3.0)
    override func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        self.insertionSectionIndexSet.add(sections)
        if let callback = insertSectionsCallback {
            callback(sections)
        }
    }
    #else
    override func insertSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionSectionIndexSet.addIndexes(sections)
        if let callback = insertSectionsCallback {
            callback(indexSet: sections)
        }
    }
    #endif

    #if swift(>=3.0)
    override func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        self.deletionSectionIndexSet.add(sections)
        if let callback = deleteSectionsCallback {
            callback(sections)
        }
    }
    #else
    override func deleteSections(sections: NSIndexSet, withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionSectionIndexSet.addIndexes(sections)
        if let callback = deleteSectionsCallback {
            callback(indexSet: sections)
        }
    }
    #endif

    #if swift(>=3.0)
    override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        self.insertionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths)
        }
    }
    #else
    override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }
    #endif

    #if swift(>=3.0)
    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        self.deletionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }
    #else
    override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
    }
    #endif

}
