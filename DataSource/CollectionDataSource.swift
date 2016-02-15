// swiftlint:disable line_length
//
//  CollectionDataSource.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 28.12.15.
//  Copyright © 2015-2016 Ruotger Deecke. All rights reserved.
//
//
// TL/DR; BSD 2-clause license
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
// following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
//    disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
//    following disclaimer in the documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import UIKit

let kStandardSection = "build-in standard section"

public class CollectionDataSource <T where T: DataItem> : NSObject, UICollectionViewDelegate, UICollectionViewDataSource {

    private let collectionView: UICollectionView
    private let engine: DataSourceEngine<T>

    // MARK: - logging / failing

    func setFailFunc(failFunc: (String) -> Void) {
        self.engine.fail = failFunc
    }
    func setWarnFunc(warnFunc: (String) -> Void) {
        self.engine.warn = warnFunc
    }
    func setReportingLevel(level: DataSourceReportingLevel) {
        self.engine.reportingLevel = level
    }

    // MARK: - trampoline methods
    public var cell: (forLocation: Location<T>) -> UICollectionViewCell
    public var didSelect: ((inLocation: Location<T>) -> Void)?
    public var canMove: ((toLocation: Location<T>) -> Bool)?
    public func setDidChangeSectionIDsFunc(didChangeFunc: ((inSectionIDs: Dictionary<String, Array<T>>) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeFunc
    }

    // MARK: -
    public init(collectionView: UICollectionView, cellForLocationCallback cellForLocation: (inLocation: Location<T>) -> UICollectionViewCell) {
        self.engine = DataSourceEngine<T>()
        self.collectionView = collectionView
        self.cell = cellForLocation
        super.init()

        self.collectionView.dataSource = self
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in self.collectionView.deleteSections(indexSet) }
        self.engine.insertSections = { indexSet in self.collectionView.insertSections(indexSet) }
        self.engine.insertRowsAtIndexPaths = { indexPaths in self.collectionView.insertItemsAtIndexPaths(indexPaths) }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in self.collectionView.deleteItemsAtIndexPaths(indexPaths) }
}

    // MARK: - querying
    public func sections() -> [String] {
        let sections = self.engine.sections()
        return sections
    }

    public func rowsForSection(section: String) -> [T] {
        return self.engine.rowsForSection(section)
    }

    public func sectionIDAndItemForIndexPath(inIndexPath: NSIndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItemForIndexPath(inIndexPath)
    }

    public func dequeueReusableCellWithReuseIdentifier(reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UICollectionViewCell? {
        guard let indexPath = self.engine.indexPathForSectionID(inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
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
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.updateRows(inRows, section: inSectionID, animated: inAnimated)
            }, completion: nil)
    }

    // MARK: - delegate / data source
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

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let callback = self.didSelect else {
            return
        }

        guard let location = self.engine.locationForIndexPath(indexPath) else {
            return
        }

        callback(inLocation: location)
    }

    public func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool {

        guard let canActuallyMove = self.canMove else {
            // callback not implemented, so... no, you can't!
            return false
        }

        guard let location = self.engine.locationForIndexPath(indexPath) else {
            return false
        }

        return canActuallyMove(toLocation: location)
    }

    public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.engine.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
    }
}
