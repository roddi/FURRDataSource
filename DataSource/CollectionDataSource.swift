//
//  CollectionDataSource.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 28.12.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit

let kStandardSection = "build-in standard section"

public class CollectionDataSource <T where T: DataItem> : NSObject, UICollectionViewDelegate, UICollectionViewDataSource {

    private let collectionView: UICollectionView
    private let engine: DataSourceEngine<T>

    public var cell: (forLocation: Location<T>) -> UICollectionViewCell

    public init(collectionView: UICollectionView, cellForLocationCallback cellForLocation:(inLocation:Location<T>) -> UICollectionViewCell) {
        self.engine = DataSourceEngine<T>()
        self.collectionView = collectionView
        self.cell = cellForLocation
        super.init()

        self.collectionView.dataSource = self
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in self.collectionView.deleteSections(indexSet) }
        self.engine.insertSections = { indexSet in self.collectionView.insertSections(indexSet) }
        self.engine.insertRowsAtIndexPaths = { indexPaths in }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in }
}

    // MARK: - querying
    public func sections() -> [String] {
        return self.engine.sections()
    }

    public func rowsForSection(section: String) -> [T] {
        return self.engine.rowsForSection(section)
    }

    public func sectionIDAndItemForIndexPath(inIndexPath: NSIndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItemForIndexPath(inIndexPath)
    }

    public func dequeueReusableCellWithIdentifier(identifier: String, sectionID inSectionID: String, item inItem: T) -> UICollectionViewCell? {
        guard let indexPath = self.engine.indexPathForSectionID(inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    }
    
    func selectedLocations() -> [Location<T>] {
        let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems()
        guard let selectedIndexPaths_ = selectedIndexPaths else {
            return []
        }
        let selectedLocations: [Location<T>] = selectedIndexPaths_.flatMap({ (indexPath) -> Location<T>? in
            return self.engine.locationForIndexPath(indexPath)
        })

        return selectedLocations
    }

    // MARK: - updating
    public func updateSections(inSections: Array<String>, animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.updateSections(inSections, animated: inAnimated)
            }, completion: nil)

    }

    public func updateRows(inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        self.engine.updateRows(inRows, section: inSectionID, animated: inAnimated)
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.engine.numberOfRowsForSectionIndex(section)
    }

    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.engine.sections().count
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let location = self.engine.locationForIndexPath(indexPath) else {
            preconditionFailure("rows not found")
        }

        return self.cell(forLocation: location)
    }
}
