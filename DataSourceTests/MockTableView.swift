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

    var insertRowsCallback: (([IndexPath]) -> Void)?
    var deleteRowsCallback: (([IndexPath]) -> Void)?
    var insertSectionsCallback: ((IndexSet) -> Void)?
    var deleteSectionsCallback: ((IndexSet) -> Void)?

    var insertionRowIndexPaths: [IndexPath] = []
    var deletionRowIndexPaths: [IndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    override func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        self.insertionSectionIndexSet.add(sections)
        if let callback = insertSectionsCallback {
            callback(sections)
        }
    }

    override func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        self.deletionSectionIndexSet.add(sections)
        if let callback = deleteSectionsCallback {
            callback(sections)
        }
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        self.insertionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths)
        }
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        self.deletionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths)
        }
    }
}
