//
//  MockTableView.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 19.10.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit

class MockTableView: UITableView {

    var insertCallback: ((indexPaths: [NSIndexPath]) -> Void)?
    var deleteCallback: ((indexPaths: [NSIndexPath]) -> Void)?

    var insertionIndexPaths: [NSIndexPath] = []
    var deletionIndexPaths: [NSIndexPath] = []

    override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.insertionIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.insertCallback {
            callback(indexPaths: indexPaths)
        }
    }

    override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        self.deletionIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.deleteCallback {
            callback(indexPaths: indexPaths)
        }
    }

}
