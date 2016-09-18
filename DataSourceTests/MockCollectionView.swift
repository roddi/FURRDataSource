//
//  MockCollectionView.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 14.01.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import UIKit
@testable import FURRDataSource

class MockCollectionView: UICollectionView {

    var insertRowsCallback: (([CompatIndexPath]) -> Void)?
    var deleteRowsCallback: (([CompatIndexPath]) -> Void)?
    var insertSectionsCallback: ((NSIndexSet) -> Void)?
    var deleteSectionsCallback: ((NSIndexSet) -> Void)?

    var insertionRowIndexPaths: [CompatIndexPath] = []
    var deletionRowIndexPaths: [CompatIndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    #if swift(>=3.0)
    override func insertSections(_ sections: IndexSet) {
        self.insertionSectionIndexSet.add(sections)
        if let callback = insertSectionsCallback {
            callback(sections)
        }
        super.insertSections(sections)
    }
    #else
    override func insertSections(sections: NSIndexSet) {
        self.insertionSectionIndexSet.addIndexes(sections)
        if let callback = insertSectionsCallback {
            callback(indexSet: sections)
        }
        super.insertSections(sections)
    }
    #endif

    #if swift(>=3.0)
    override func deleteSections(_ sections: IndexSet) {
        self.deletionSectionIndexSet.add(sections)
        if let callback = deleteSectionsCallback {
            callback(indexSet: sections)
        }
        super.deleteSections(sections)
    }
    #else
    override func deleteSections(sections: NSIndexSet) {
        self.deletionSectionIndexSet.addIndexes(sections)
        if let callback = deleteSectionsCallback {
            callback(indexSet: sections)
        }
        super.deleteSections(sections)
    }
    #endif

    #if swift(>=3.0)
    override func insertItems(at indexPaths: [IndexPath]) {
        self.insertionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths: indexPaths)
        }
        super.insertItems(at: indexPaths)
    }
    #else
    override func insertItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        self.insertionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths: indexPaths)
        }
        super.insertItemsAtIndexPaths(indexPaths)
    }
    #endif

    #if swift(>=3.0)
    override func deleteItems(at indexPaths: [IndexPath]) {
        self.deletionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
        super.deleteItems(at: indexPaths)
    }
    #else
    override func deleteItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        self.deletionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
        super.deleteItemsAtIndexPaths(indexPaths)
    }
    #endif
}

class MockCollectionViewCell: UICollectionViewCell {
}
