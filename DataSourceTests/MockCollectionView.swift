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

    var insertRowsCallback: (([IndexPath]) -> Void)?
    var deleteRowsCallback: (([IndexPath]) -> Void)?
    var insertSectionsCallback: ((IndexSet) -> Void)?
    var deleteSectionsCallback: ((IndexSet) -> Void)?

    var insertionRowIndexPaths: [IndexPath] = []
    var deletionRowIndexPaths: [IndexPath] = []
    var insertionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSMutableIndexSet = NSMutableIndexSet()

    override func insertSections(_ sections: IndexSet) {
        self.insertionSectionIndexSet.add(sections)
        if let callback = insertSectionsCallback {
            callback(sections)
        }
        super.insertSections(sections)
    }

    override func deleteSections(_ sections: IndexSet) {
        self.deletionSectionIndexSet.add(sections)
        if let callback = deleteSectionsCallback {
            callback(sections)
        }
        super.deleteSections(sections)
    }

    override func insertItems(at indexPaths: [IndexPath]) {
        self.insertionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.insertRowsCallback {
            callback(indexPaths)
        }
        super.insertItems(at: indexPaths)
    }

    override func deleteItems(at indexPaths: [IndexPath]) {
        self.deletionRowIndexPaths.append(contentsOf: indexPaths)
        if let callback = self.deleteRowsCallback {
            callback(indexPaths)
        }
        super.deleteItems(at: indexPaths)
    }
}

class MockCollectionViewCell: UICollectionViewCell {
}
