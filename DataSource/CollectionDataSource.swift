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

public class CollectionDataSource <T> : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, Reporting where T: DataItem {

    private let collectionView: UICollectionView
    private let engine: DataSourceEngine<T>

    // MARK: - logging / failing

    public func setFunc(fail failFunc: ((String) -> Void )?) {
        self.engine.fail = failFunc
    }
    public func setFunc(warn warnFunc: ((String) -> Void )?) {
        self.engine.warn = warnFunc
    }
    public func setReporting(level inLevel: DataSourceReportingLevel) {
        self.engine.reportingLevel = inLevel
    }

    // MARK: - delegate closures

    public var cellForLocation: (Location<T>) -> UICollectionViewCell
    public var didSelectLocation: ((Location<T>) -> Void)?
    public var canMoveToLocation: ((Location<T>) -> Bool)?

    public func setFunc(didChangeSectionIDsFunc: @escaping (([String: [T]]) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeSectionIDsFunc
    }

    // MARK: -

    // due to the `@escaping` in the parameter we need two complete init() methods... *sigh*
    public init(collectionView: UICollectionView, cellForLocationCallback cellForLocation: @escaping (_ inLocation: Location<T>) -> UICollectionViewCell) {
        self.engine = DataSourceEngine<T>()
        self.collectionView = collectionView
        self.cellForLocation = cellForLocation
        super.init()

        setup()
    }

    private func setup() {
        self.collectionView.dataSource = self
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in self.collectionView.deleteSections(indexSet) }
        self.engine.insertSections = { indexSet in self.collectionView.insertSections(indexSet) }
        self.engine.insertRowsAtIndexPaths = { indexPaths in
            self.collectionView.insertItems(at: indexPaths)
        }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in
            self.collectionView.deleteItems(at: indexPaths)
        }
    }

    // MARK: - querying
    public func sections() -> [String] {
        let sections = self.engine.sections()
        return sections
    }

    public func rows(forSection: String) -> [T] {
        return self.engine.rows(forSection: forSection)
    }

    public func sectionIDAndItem(forIndexPath: IndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItem(forIndexPath: forIndexPath)
    }

    public func dequeueReusableCell(withReuseIdentifier: String, sectionID: String, item: T) -> UICollectionViewCell? {
        guard let indexPath = self.engine.indexPath(forSectionID: sectionID, rowItem: item) else {
            return nil
        }

        return self.collectionView.dequeueReusableCell(withReuseIdentifier: withReuseIdentifier, for: indexPath)
    }

    func selectedLocations() -> [Location<T>] {
        let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
        guard let selectedIndexPaths_ = selectedIndexPaths else {
            return []
        }
        let selectedLocations: [Location<T>] = selectedIndexPaths_.flatMap({ (indexPath) -> Location<T>? in
            return self.engine.location(forIndexPath: indexPath)
        })

        return selectedLocations
    }

    // MARK: - updating

    func update(sections inSections: [String], animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.update(sections: inSections, animated: inAnimated)
        }, completion: nil)

    }

    public func update(rows inRows: [T], section inSectionID: String, animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.update(rows: inRows, section: inSectionID, animated: inAnimated)
        }, completion: nil)
    }

    // MARK: updating, convenience

    public func deleteItems(_ items: [T], animated: Bool = true) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.deleteItems(items, animated: animated)
        }, completion: nil)
    }

    // MARK: - delegate / data source

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.engine.numberOfRows(forSectionIndex: section)
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.engine.sections().count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let location = self.engine.location(forIndexPath: indexPath) else {
            preconditionFailure("rows not found")
        }

        return self.cellForLocation(location)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let didSelectLocation = self.didSelectLocation else {
            return
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return
        }

        didSelectLocation(location)
    }

    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {

        guard let canActuallyMove = self.canMoveToLocation else {
            // callback not implemented, so... no, you can't!
            return false
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return false
        }

        return canActuallyMove(location)
    }

    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.engine.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
}
