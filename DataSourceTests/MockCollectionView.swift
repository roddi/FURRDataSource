//
//  MockCollectionView.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 14.01.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import UIKit

class MockCollectionView: UICollectionView {

    var insertRowsCallback: ((indexPaths: [NSIndexPath]) -> Void)?
    var deleteRowsCallback: ((indexPaths: [NSIndexPath]) -> Void)?
    var insertSectionsCallback: ((indexSet: NSIndexSet) -> Void)?
    var deleteSectionsCallback: ((indexSet: NSIndexSet) -> Void)?

    var insertionRowIndexPaths: [NSIndexPath] = []
    var deletionRowIndexPaths: [NSIndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    override func insertSections(sections: NSIndexSet) {
        self.insertionSectionIndexSet.addIndexes(sections)
        if let callback = insertSectionsCallback {
            callback(indexSet: sections)
        }
        super.insertSections(sections)
    }

    override func deleteSections(sections: NSIndexSet) {
        self.deletionSectionIndexSet.addIndexes(sections)
        if let callback = deleteSectionsCallback {
            callback(indexSet: sections)
        }
        super.deleteSections(sections)
    }

    override func insertItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        self.insertionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths: indexPaths)
        }
        super.insertItemsAtIndexPaths(indexPaths)
    }

    override func deleteItemsAtIndexPaths(indexPaths: [NSIndexPath]) {
        self.deletionRowIndexPaths.appendContentsOf(indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths: indexPaths)
        }
        super.deleteItemsAtIndexPaths(indexPaths)
    }
}

class MockCollectionViewCell: UICollectionViewCell {
}
