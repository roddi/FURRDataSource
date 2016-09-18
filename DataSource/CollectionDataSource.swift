// swiftlint:disable type_body_length
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

public class CollectionDataSource <T where T: DataItem> : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, Reporting {

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

    #if !swift(>=3.0)
    @available(*, deprecated) public func setFailFunc(failFunc: (String) -> Void) {
        self.engine.fail = failFunc
    }
    @available(*, deprecated) public func setWarnFunc(warnFunc: (String) -> Void) {
        self.engine.warn = warnFunc
    }
    @available(*, deprecated) public func setReportingLevel(level: DataSourceReportingLevel) {
        self.engine.reportingLevel = level
    }

    // MARK: - trampoline methods
    @available(*, deprecated, renamed="cellForLocation()", message="Thanks Apple for SE-111!")
    public var cell: (forLocation: Location<T>) -> UICollectionViewCell {
        set(cell) {
            self.cellForLocation = { (location: Location<T>) -> UICollectionViewCell in cell(forLocation: location) }
        }
        get {
            preconditionFailure("write-only. Use 'cellForLocation' if you need to read")
        }
    }
    @available(*, deprecated, renamed="didSelectLocation()", message="Thanks Apple for SE-111!")
    public var didSelect: ((inLocation: Location<T>) -> Void)? {
        set(selectFunc) {
            if selectFunc != nil {
                self.didSelectLocation = { (location: Location<T>) -> Void in selectFunc?(inLocation: location) }
            } else {
                self.didSelectLocation = nil
            }
        }
        get {
            preconditionFailure("write-only. Use 'didSelectLocation' if you need to read")
        }
    }
    @available(*, deprecated, renamed="canMoveToLocation()", message="Thanks Apple for SE-111!")
    public var canMove: ((toLocation: Location<T>) -> Bool)? {
        set(moveFunc) {
            if moveFunc != nil {
                self.canMoveToLocation = { (location: Location<T>) -> Bool in
                    return moveFunc != nil ? moveFunc!(toLocation: location) : false
                }
            } else {
                self.canMoveToLocation = nil
            }
        }
        get {
            preconditionFailure("write-only. Use 'canMoveToLocation' if you need to read")
        }
    }
    @available(*, deprecated, renamed="setFunc(didChangeSectionIDsFunc:)", message="Thanks Apple for SE-111!")
    public func setDidChangeSectionIDsFunc(didChangeFunc: ((inSectionIDs: Dictionary<String, Array<T>>) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeFunc
    }

    #endif

    public var cellForLocation: (Location<T>) -> UICollectionViewCell
    public var didSelectLocation: ((Location<T>) -> Void)?
    public var canMoveToLocation: ((Location<T>) -> Bool)?

    #if !swift(>=3.0)
    public func setFunc(didChangeSectionIDsFunc: ((Dictionary<String, Array<T>>) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeSectionIDsFunc
    }
    #else
    public func setFunc(didChangeSectionIDsFunc: @escaping ((Dictionary<String, Array<T>>) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeSectionIDsFunc
    }
    #endif


    // MARK: -

    // due to the `@escaping` in the parameter we need two complete init() methods... *sigh*
    #if !swift(>=3.0)
    public init(collectionView: UICollectionView, cellForLocationCallback cellForLocation: (inLocation: Location<T>) -> UICollectionViewCell) {
        self.engine = DataSourceEngine<T>()
        self.collectionView = collectionView
        self.cellForLocation = cellForLocation
        super.init()

        setup()
    }
    #else
    public init(collectionView: UICollectionView, cellForLocationCallback cellForLocation: @escaping (Location<T>) -> UICollectionViewCell) {
        self.engine = DataSourceEngine<T>()
        self.collectionView = collectionView
        self.cellForLocation = cellForLocation
        super.init()

        setup()
    }
    #endif

    private func setup() {
        self.collectionView.dataSource = self
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in self.collectionView.deleteSections(indexSet) }
        self.engine.insertSections = { indexSet in self.collectionView.insertSections(indexSet) }
        self.engine.insertRowsAtIndexPaths = { indexPaths in
            #if swift(>=3.0)
                self.collectionView.insertItems(at: indexPaths)
            #else
                self.collectionView.insertItemsAtIndexPaths(indexPaths)
            #endif
        }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in
            #if swift(>=3.0)
                self.collectionView.deleteItems(at: indexPaths)
            #else
                self.collectionView.deleteItemsAtIndexPaths(indexPaths)
            #endif
        }
    }

    // MARK: - querying
    public func sections() -> [String] {
        let sections = self.engine.sections()
        return sections
    }

    public func rows(forSection section: String) -> [T] {
        return self.engine.rows(forSection: section)
    }
    #if !swift(>=3.0)
    @available(*, deprecated) public func rowsForSection(section: String) -> [T] {
        return self.engine.rows(forSection: section)
    }
    #endif

    #if !swift(>=3.0)
    @available(*, deprecated) public func sectionIDAndItemForIndexPath(inIndexPath: CompatIndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItem(forIndexPath: inIndexPath)
    }
    #endif
    public func sectionIDAndItem(forIndexPath inIndexPath: CompatIndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItem(forIndexPath: inIndexPath)
    }

    #if !swift(>=3.0)
    @available(*, deprecated) public func dequeueReusableCellWithReuseIdentifier(reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UICollectionViewCell? {
        guard let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    }
    #endif
    public func dequeueReusableCell(withReuseIdentifier reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UICollectionViewCell? {
        guard let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) else {
            return nil
        }

        #if swift(>=3.0)
            return self.collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        #else
            return self.collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        #endif
    }

    func selectedLocations() -> [Location<T>] {
        #if swift(>=3.0)
            let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems
        #else
            let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems()
        #endif
        guard let selectedIndexPaths_ = selectedIndexPaths else {
            return []
        }
        let selectedLocations: [Location<T>] = selectedIndexPaths_.flatMap({ (indexPath) -> Location<T>? in
            return self.engine.location(forIndexPath: indexPath)
        })

        return selectedLocations
    }

    // MARK: - updating
    #if !swift(>=3.0)
    @available(*, deprecated) public func updateSections(inSections: Array<String>, animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.update(sections: inSections, animated: inAnimated)
            }, completion: nil)

    }
    #endif
    func update(sections inSections: Array<String>, animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.update(sections: inSections, animated: inAnimated)
            }, completion: nil)

    }

    #if !swift(>=3.0)
    @available(*, deprecated) public func updateRows(inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.update(rows: inRows, section: inSectionID, animated: inAnimated)
            }, completion: nil)
    }
    #endif
    public func update(rows inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        self.collectionView.performBatchUpdates({ () -> Void in
            self.engine.update(rows: inRows, section: inSectionID, animated: inAnimated)
            }, completion: nil)
    }

    // MARK: -
    // MARK: - delegate / data source
    #if swift(>=3.0)
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.engine.numberOfRows(forSectionIndex: section)
    }
    #else
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.engine.numberOfRows(forSectionIndex: section)
    }
    #endif


    #if swift(>=3.0)
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
                return self.engine.sections().count
    }
    #else
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.engine.sections().count
    }
    #endif

    #if swift(>=3.0)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return private_collectionView(collectionView: collectionView, cellForItemAt: indexPath)
    }
    #else
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: CompatIndexPath) -> UICollectionViewCell {
        return private_collectionView(collectionView, cellForItemAt: indexPath)
    }
    #endif
    private func private_collectionView(collectionView: UICollectionView, cellForItemAt indexPath: CompatIndexPath) -> UICollectionViewCell {
        guard let location = self.engine.location(forIndexPath: indexPath) else {
            preconditionFailure("rows not found")
        }

        return self.cellForLocation(location)
    }


    #if swift(>=3.0)
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        private_collectionView(collectionView: collectionView, didSelectItemAt: indexPath)
    }
    #else
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        private_collectionView(collectionView, didSelectItemAt: indexPath)
    }
    #endif
    private func private_collectionView(collectionView: UICollectionView, didSelectItemAt indexPath: CompatIndexPath) {
        guard let didSelectLocation = self.didSelectLocation else {
            return
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return
        }

        didSelectLocation(location)
    }

    #if swift(>=3.0)
    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return private_collectionView(collectionView: collectionView, canMoveItemAtIndexPath: indexPath)
    }
    #else
    public func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return private_collectionView(collectionView, canMoveItemAtIndexPath: indexPath)
    }
    #endif

    private func private_collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: CompatIndexPath) -> Bool {

        guard let canActuallyMove = self.canMoveToLocation else {
            // callback not implemented, so... no, you can't!
            return false
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return false
        }

        return canActuallyMove(location)
    }

    #if swift(>=3.0)
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return private_collectionView(collectionView: collectionView, moveItemAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    #else
    public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: CompatIndexPath) {
    return private_collectionView(collectionView, moveItemAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    #endif


    private func private_collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: CompatIndexPath, toIndexPath destinationIndexPath: CompatIndexPath) {
        self.engine.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
}
