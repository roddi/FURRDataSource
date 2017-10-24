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
    var reloadRowsCallback: (([IndexPath]) -> Void)?
    var insertSectionsCallback: ((IndexSet) -> Void)?
    var deleteSectionsCallback: ((IndexSet) -> Void)?

    var dequeuedCellCallback: ((_ textLabel: String?, _ detalTextLabel: String?) -> Void)?

    var insertionRowIndexPaths: [IndexPath] = []
    var deletionRowIndexPaths: [IndexPath] = []
    var reloadRowIndexPaths: [IndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    override func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        insertionSectionIndexSet.add(sections)
        insertSectionsCallback?(sections)
    }

    override func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        deletionSectionIndexSet.add(sections)
        deleteSectionsCallback?(sections)
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        insertionRowIndexPaths.append(contentsOf: indexPaths)
        insertRowsCallback?(indexPaths)
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        deletionRowIndexPaths.append(contentsOf: indexPaths)
        deleteRowsCallback?(indexPaths)
    }

    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        reloadRowIndexPaths.append(contentsOf: indexPaths)
        reloadRowsCallback?(indexPaths)
    }

    override func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        let cell = super.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        dequeuedCellCallback?(cell.textLabel?.text, cell.detailTextLabel?.text)
        return cell
    }
}
