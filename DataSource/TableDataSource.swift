// swiftlint:disable line_length
//
//  TableDataSource.swift
//  DBDB
//
//  Created by Ruotger Deecke on 27.07.15.
//  Copyright © 2015-2016 Deecke,Roddi. All rights reserved.
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
import FURRExtensions

public class TableDataSource <T where T: DataItem> : NSObject, UITableViewDelegate, UITableViewDataSource {

    private let tableView: UITableView
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
    public var cell: (forLocation: Location<T>) -> UITableViewCell
    public var didSelect: ((inLocation: Location<T>) -> Void)?
    public var canMove: ((toLocation: Location<T>) -> Bool)?
    public var targetMovedItem: ((fromLocation: Location<T>, proposedLocation: LocationWithOptionalItem<T>) -> LocationWithOptionalItem<T>)?
    public var canEdit: ((atLocation: Location<T>) -> Bool)?
    public var willDelete: ((atLocation: Location<T>) -> Void)?
    public var didDelete: ((item: T) -> Void)?

    public var sectionHeaderTitle: ((sectionID: String) -> String)?
    public var sectionFooterTitle: ((sectionID: String) -> String)?

    public func setDidChangeSectionIDsFunc(didChangeFunc: ((inSectionIDs: Dictionary<String, Array<T>>) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeFunc
    }

    // MARK: -
    public init(tableView inTableView: UITableView, cellForLocationCallback inCellForLocation: (inLocation: Location<T>) -> UITableViewCell) {
        self.engine = DataSourceEngine<T>()
        self.tableView = inTableView
        self.cell = inCellForLocation

        super.init()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.engine.beginUpdates = {self.tableView.beginUpdates()}
        self.engine.endUpdates = {self.tableView.endUpdates()}
        self.engine.deleteSections = { indexSet in self.tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic) }
        self.engine.insertSections = { indexSet in self.tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic) }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)}
        self.engine.insertRowsAtIndexPaths = { indexPaths in self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)}
        self.engine.didChangeSectionIDs = { sectionIDs in }
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


    // MARK: - updating
    public func updateSections(inSections: Array<String>, animated inAnimated: Bool) {
        self.engine.updateSections(inSections, animated: inAnimated)
    }

    public func updateRows(inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        self.engine.updateRows(inRows, section: inSectionID, animated: inAnimated)
    }

    public func dequeueReusableCellWithReuseIdentifier(reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UITableViewCell? {
        guard let indexPath = self.engine.indexPathForSectionID(inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
    }

    public func reloadAll() {
        self.tableView.reloadData()
    }

    public func reloadSectionID(inSectionID: String) {
        if let sectionID = self.engine.sectionIndexForSectionID(inSectionID) {
            self.tableView.reloadSections(NSIndexSet(index: sectionID), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    public func reloadSectionID(inSectionID: String, item inItem: T) {
        if let indexPath = self.engine.indexPathForSectionID(inSectionID, rowItem: inItem) {
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    // MARK: - UITableViewDataSource

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = self.engine.sections()
        return sections.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection inSection: Int) -> Int {
        return self.engine.numberOfRowsForSectionIndex(inSection)
    }


    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let location = self.engine.locationForIndexPath(indexPath) else {
            preconditionFailure("rows not found")
        }

        return self.cell(forLocation: location)
    }

    public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let canActuallyMove = self.canMove else {
            // callback not implemented, so... no, you can't!
            return false
        }

        guard let location = self.engine.locationForIndexPath(indexPath) else {
            return false
        }

        return canActuallyMove(toLocation: location)
    }

    public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.engine.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
    }

    public func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        guard let callback = self.targetMovedItem else {
            return proposedDestinationIndexPath
        }

        guard let fromLocation = self.engine.locationForIndexPath(sourceIndexPath) else {
            print("source not found!")
            return proposedDestinationIndexPath
        }

        guard let toLocation = self.engine.locationWithOptionalItemForIndexPath(proposedDestinationIndexPath) else {
            print("destination section not found!")
            return proposedDestinationIndexPath
        }

        // ask the our delegate where he/she wants the row
        let actualDestination = callback(fromLocation: fromLocation, proposedLocation: toLocation)

        // check whether actual destination is OK
        if let item = actualDestination.item, let indexPath = self.engine.indexPathForSectionID(actualDestination.sectionID, rowItem: item) {
            return indexPath
        }

        guard let sectionIndex = self.engine.sectionIndexForSectionID(actualDestination.sectionID) else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }

        let rows = self.engine.rowsForSection(actualDestination.sectionID)
        if  rows.count != 0 {
            return NSIndexPath(forRow: rows.count-1, inSection: sectionIndex)
        } else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }
    }

    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        switch editingStyle {
        case .Delete:
            guard let location = self.engine.locationForIndexPath(indexPath) else {
                return
            }

            if let callback = self.willDelete {
                callback(atLocation: location)
            }

            var rows = self.engine.rowsForSection(location.sectionID)
            if rows.count != 0 {
                rows.removeAtIndex(indexPath.row)
                self.engine.updateRows(rows, section: location.sectionID, animated: true)
            }

            if let callback = self.didDelete {
                callback(item: location.item)
            }

            // HACK? Is this really the right thing to do here conceptually???
            if let callback = self.engine.didChangeSectionIDs {
                let sectionID = location.sectionID
                let rows = self.engine.rowsForSection(sectionID)
                callback(inSectionIDs: [sectionID:rows])
            }

        case .Insert:
            print(".Insert ????")

        case .None:
            print(".None ????")
        }
    }

    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let location = self.engine.locationForIndexPath(indexPath) else {
            return false
        }

        guard let callback = self.canEdit else {
            return false
        }

        return callback(atLocation: location)
    }

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionID = self.engine.sections().optionalElementAtIndex(section) else {
            self.engine.warnWithMessage("section not found at index \(section)")
            return nil
        }

        guard let callback = self.sectionHeaderTitle else {
            return nil
        }

        return callback(sectionID: sectionID)

    }

    public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionID = self.engine.sections().optionalElementAtIndex(section) else {
            self.engine.warnWithMessage("section not found at index \(section)")
            return nil
        }

        guard let callback = self.sectionFooterTitle else {
            return nil
        }

        return callback(sectionID: sectionID)
    }


}


    // MARK: - UITableViewDelegate

extension TableDataSource {
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let callback = self.didSelect else {
            return
        }

        guard let location = self.engine.locationForIndexPath(indexPath) else {
            return
        }

        callback(inLocation: location)
    }
}

// swiftlint:enable file_length
