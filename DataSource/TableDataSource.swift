// swiftlint:disable line_length
// swiftlint:disable file_length
// swiftlint:disable type_body_length

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

public class TableDataSource <T where T: DataItem> : NSObject, UITableViewDelegate, UITableViewDataSource, Reporting {

    private let tableView: UITableView
    private let engine: DataSourceEngine<T>

    // MARK: - logging / failing
    func setFunc(fail failFunc: ((String) -> Void )?) {
        self.engine.fail = failFunc
    }
    func setFunc(warn warnFunc: ((String) -> Void )?) {
        self.engine.warn = warnFunc
    }
    func setReporting(level inLevel: DataSourceReportingLevel) {
        self.engine.reportingLevel = inLevel
    }

    #if !swift(>=3.0)
    @available(*, deprecated) func setFailFunc(failFunc: (String) -> Void) {
        self.engine.fail = failFunc
    }

    @available(*, deprecated) func setWarnFunc(warnFunc: (String) -> Void) {
        self.engine.warn = warnFunc
    }

    @available(*, deprecated) func setReportingLevel(level: DataSourceReportingLevel) {
        self.engine.reportingLevel = level
    }

    #endif

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
        self.engine.logWhenVerbose(message: "TableDataSource.init(,cellForLocation:)")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.engine.beginUpdates = {self.tableView.beginUpdates()}
        self.engine.endUpdates = {self.tableView.endUpdates()}
        self.engine.deleteSections = { indexSet in
            #if swift(>=3.0)
                self.tableView.deleteSections(indexSet, with: UITableViewRowAnimation.automatic)
            #else
                self.tableView.deleteSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
            #endif
        }
        self.engine.insertSections = { indexSet in
            #if swift(>=3.0)
                self.tableView.insertSections(indexSet, with: UITableViewRowAnimation.automatic)
            #else
                self.tableView.insertSections(indexSet, withRowAnimation: UITableViewRowAnimation.Automatic)
            #endif
        }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in
            #if swift(>=3.0)
                self.tableView.deleteRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
            #else
                self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            #endif
        }
        self.engine.insertRowsAtIndexPaths = { indexPaths in
            #if swift(>=3.0)
                self.tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
            #else
                self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            #endif
        }
        self.engine.didChangeSectionIDs = { sectionIDs in }
    }

    // MARK: - querying

    public func sections() -> [String] {
        return self.engine.sections()
    }

    #if !swift(>=3.0)
    @available(*, deprecated = 0.2) public func rowsForSection(section: String) -> [T] {
        return self.engine.rows(forSection: section)
    }
    #endif
    public func rows(forSection inSection: String) -> [T] {
        return self.engine.rows(forSection: inSection)
    }

    #if !swift(>=3.0)
    @available(*, deprecated = 0.2) public func sectionIDAndItemForIndexPath(inIndexPath: NSIndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItem(forIndexPath: inIndexPath)
    }
    #endif
    public func sectionIDAndItem(indexPath inIndexPath: IndexPathway) -> (String, T)? {
        return self.engine.sectionIDAndItem(forIndexPath: inIndexPath)
    }

    // MARK: - updating
    #if !swift(>=3.0)
    @available(*, deprecated = 0.2) public func updateSections(inSections: Array<String>, animated inAnimated: Bool) {
    self.engine.update(sections: inSections, animated: inAnimated)
    }
    #endif
    public func update(sections inSections: Array<String>, animated inAnimated: Bool) {
        self.engine.update(sections: inSections, animated: inAnimated)
    }

    #if !swift(>=3.0)
    @available(*, deprecated = 0.2) public func updateRows(inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        self.engine.update(rows: inRows, section: inSectionID, animated: inAnimated)
    }
    #endif
    public func update(rows inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        self.engine.update(rows: inRows, section: inSectionID, animated: inAnimated)
    }

    #if !swift(>=3.0)
    @available(*, deprecated) public func dequeueReusableCellWithReuseIdentifier(reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UITableViewCell? {
        guard let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
    }
    #endif
    public func dequeueReusableCell(withIdentifier reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UITableViewCell? {
        guard let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) else {
            return nil
        }

        #if swift(>=3.0)
            return self.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        #else
            return self.tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
        #endif
    }

    public func reloadAll() {
        self.tableView.reloadData()
    }

    #if !swift(>=3.0)
    @available(*, deprecated) public func reloadSectionID(inSectionID: String) {
        if let sectionID = self.engine.sectionIndex(forSectionID: inSectionID) {
                self.tableView.reloadSections(NSIndexSet(index: sectionID), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    #endif
    public func reload(sectionID inSectionID: String) {
        if let sectionID = self.engine.sectionIndex(forSectionID: inSectionID) {
            #if swift(>=3.0)
                self.tableView.reloadSections(IndexSet(integer: sectionID), with: UITableViewRowAnimation.automatic)
            #else
                self.tableView.reloadSections(NSIndexSet(index: sectionID), withRowAnimation: UITableViewRowAnimation.Automatic)
            #endif
        }
    }

    #if !swift(>=3.0)
    @available(*, deprecated) public func reloadSectionID(inSectionID: String, item inItem: T) {
        if let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) {
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    #endif
    public func reload(sectionID inSectionID: String, item inItem: T) {
        if let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) {
            #if swift(>=3.0)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            #else
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            #endif
        }
    }


    // MARK: -
    // MARK: UITableViewDataSource
    #if swift(>=3.0)
    public func numberOfSections(in tableView: UITableView) -> Int {
        return private_numberOfSectionsInTableView(tableView: tableView)
    }
    #else
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return private_numberOfSectionsInTableView(tableView)
    }
    #endif
    private func private_numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = self.engine.sections()
        self.engine.logWhenVerbose(message: "TableDataSource.numberOfSectionsInTableView() -> \(sections.count)")
        return sections.count
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return private_tableView(tableView: tableView, numberOfRowsInSection: section)
    }
    #else
    public func tableView(tableView: UITableView, numberOfRowsInSection inSection: Int) -> Int {
        return private_tableView(tableView, numberOfRowsInSection: inSection)
    }
    #endif
    private func private_tableView(tableView: UITableView, numberOfRowsInSection inSection: Int) -> Int {
        let numberOfRows = self.engine.numberOfRows(forSectionIndex: inSection)
        self.engine.logWhenVerbose(message: "tableView(,numberOfRowsInSection: \(inSection)) -> \(numberOfRows)")
        return numberOfRows
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return private_tableView(tableView: tableView, cellForRowAtIndexPath: indexPath)
    }
    #else
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return private_tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    #endif
    private func private_tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        self.engine.logWhenVerbose(message:"tableView(,cellForRowAtIndexPath: \(indexPath))")
        guard let location = self.engine.location(forIndexPath: indexPath) else {
            preconditionFailure("rows not found")
        }

        return self.cell(forLocation: location)
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return private_tableView(tableView: tableView, canMoveRowAtIndexPath: indexPath)
    }
    #else
    public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return private_tableView(tableView, canMoveRowAtIndexPath: indexPath)
    }
    #endif
    private func private_tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPathway) -> Bool {
        guard let canActuallyMove = self.canMove else {
            // callback not implemented, so... no, you can't!
            return false
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return false
        }

        return canActuallyMove(toLocation: location)
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.engine.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
    #else
    public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    self.engine.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
    #endif

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return private_tableView(tableView: tableView, targetIndexPathForMoveFromRowAtIndexPath: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath)
    }
    #else
    public func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        return private_tableView(tableView, targetIndexPathForMoveFromRowAtIndexPath: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath)
    }
    #endif
    private func private_tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: IndexPathway, toProposedIndexPath proposedDestinationIndexPath: IndexPathway) -> IndexPathway {
        guard let callback = self.targetMovedItem else {
            return proposedDestinationIndexPath
        }

        guard let fromLocation = self.engine.location(forIndexPath: sourceIndexPath) else {
            print("source not found!")
            return proposedDestinationIndexPath
        }

        guard let toLocation = self.engine.locationWithOptionalItem(forIndexPath: proposedDestinationIndexPath) else {
            print("destination section not found!")
            return proposedDestinationIndexPath
        }

        // ask the our delegate where he/she wants the row
        let actualDestination = callback(fromLocation: fromLocation, proposedLocation: toLocation)

        // check whether actual destination is OK
        if let item = actualDestination.item, indexPath = self.engine.indexPath(forSectionID: actualDestination.sectionID, rowItem: item) {
            return indexPath
        }

        guard let sectionIndex = self.engine.sectionIndex(forSectionID: actualDestination.sectionID) else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }

        let rows = self.engine.rows(forSection: actualDestination.sectionID)
        if  rows.count != 0 {
            #if swift(>=3.0)
                return IndexPath(row: rows.count-1, section: sectionIndex)
            #else
                return NSIndexPath(forRow: rows.count-1, inSection: sectionIndex)
            #endif

        } else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        private_tableView(tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }
    #else
    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        private_tableView(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }
    #endif
    private func private_tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        switch CompatTableViewCellEditingStyle(editingStyle: editingStyle) {
        case .delete:
            guard let location = self.engine.location(forIndexPath: indexPath) else {
                return
            }

            if let callback = self.willDelete {
                callback(atLocation: location)
            }

            var rows = self.engine.rows(forSection: location.sectionID)
            if rows.count != 0 {
                #if swift(>=3.0)
                    rows.remove(at: indexPath.row)
                #else
                    rows.removeAtIndex(indexPath.row)
                #endif
                self.engine.update(rows: rows, section: location.sectionID, animated: true)
            }

            if let callback = self.didDelete {
                callback(item: location.item)
            }

            // HACK? Is this really the right thing to do here conceptually???
            if let callback = self.engine.didChangeSectionIDs {
                let sectionID = location.sectionID
                let rows = self.engine.rows(forSection: sectionID)
                callback(inSectionIDs: [sectionID:rows])
            }

            #if swift(>=3.0)
            #else
            #endif
        case .insert:
            print(".Insert ????")

        case .none:
            print(".None ????")
        }
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return private_tableView(tableView: tableView, canEditRowAtIndexPath: indexPath)
    }
    #else
    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return private_tableView(tableView, canEditRowAtIndexPath: indexPath)
    }
    #endif
    private func private_tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return false
        }

        guard let callback = self.canEdit else {
            return false
        }

        return callback(atLocation: location)
    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return private_tableView(tableView: tableView, titleForHeaderInSection: section)
    }
    #else
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return private_tableView(tableView, titleForHeaderInSection: section)
    }
    #endif
    private func private_tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionID = self.engine.sections().optionalElement(index: section) else {
            self.engine.warn(message: "section not found at index \(section)")
            return nil
        }

        guard let callback = self.sectionHeaderTitle else {
            return nil
        }

        return callback(sectionID: sectionID)

    }

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return private_tableView(tableView: tableView, titleForFooterInSection: section)
    }
    #else
    public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return private_tableView(tableView, titleForFooterInSection: section)
    }
    #endif
    private func private_tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionID = self.engine.sections().optionalElement(index: section) else {
            self.engine.warn(message: "section not found at index \(section)")
            return nil
        }

        guard let callback = self.sectionFooterTitle else {
            return nil
        }

        return callback(sectionID: sectionID)
    }

    // MARK: - UITableViewDelegate

    #if swift(>=3.0)
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        private_tableView(tableView: tableView, didSelectRowAtIndexPath: indexPath)
    }
    #else
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        private_tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }
    #endif
    private func private_tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let callback = self.didSelect else {
            return
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return
        }

        callback(inLocation: location)
    }
}

// swiftlint:enable file_length
