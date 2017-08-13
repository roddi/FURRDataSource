// swiftlint:disable line_length
// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable variable_name

// for swift 3 this is in conflict with what the compiler warns about
// swiftlint:disable conditional_binding_cascade

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

public class TableDataSource <T> : NSObject, UITableViewDelegate, UITableViewDataSource, Reporting where T: DataItem {

    private let tableView: UITableView
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
    public var cellForLocation: (Location<T>) -> UITableViewCell
    public var didSelectLocation: ((Location<T>) -> Void)?
    public var canMoveToLocation: ((Location<T>) -> Bool)?
    // here SE-111 shows the potentional of its deviousness
    // swiftlint:disable variable_name
    public var targetMovedItemFromLocationToProposedLocation: ((Location<T>, LocationWithOptionalItem<T>) -> LocationWithOptionalItem<T>)?
    // swiftlint:enable variable_name
    public var canEditAtLocation: ((Location<T>) -> Bool)?
    public var willDeleteAtLocation: ((Location<T>) -> Void)?
    public var didDeleteItem: ((T) -> Void)?

    public var sectionHeaderTitleForSectionID: ((String) -> String)?
    public var sectionFooterTitleForSectionID: ((String) -> String)?

    public func setFunc(didChangeSectionIDsFunc: @escaping (([String: [T]]) -> Void)) {
        self.engine.didChangeSectionIDs = didChangeSectionIDsFunc
    }

    // MARK: -
    public init(tableView inTableView: UITableView, cellForLocationCallback inCellForLocation: @escaping (_ inLocation: Location<T>) -> UITableViewCell) {
        self.engine = DataSourceEngine<T>()
        self.tableView = inTableView
        self.cellForLocation = inCellForLocation
        super.init()

        setup()
    }

    func setup() {
        self.engine.logWhenVerbose(message: "TableDataSource.init(,cellForLocation:)")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.engine.beginUpdates = {self.tableView.beginUpdates()}
        self.engine.endUpdates = {self.tableView.endUpdates()}
        self.engine.deleteSections = { indexSet in
            self.tableView.deleteSections(indexSet, with: UITableViewRowAnimation.automatic)
        }
        self.engine.insertSections = { indexSet in
            self.tableView.insertSections(indexSet, with: UITableViewRowAnimation.automatic)
        }
        self.engine.deleteRowsAtIndexPaths = { indexPaths in
            self.tableView.deleteRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
        }
        self.engine.insertRowsAtIndexPaths = { indexPaths in
            self.tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
        }
        self.engine.didChangeSectionIDs = { sectionIDs in }
    }

    // MARK: - querying

    public func sections() -> [String] {
        return self.engine.sections()
    }

    public func rows(forSection inSection: String) -> [T] {
        return self.engine.rows(forSection: inSection)
    }

    public func sectionIDAndItem(indexPath inIndexPath: IndexPath) -> (String, T)? {
        return self.engine.sectionIDAndItem(forIndexPath: inIndexPath)
    }

    // MARK: - updating

    public func update(sections inSections: [String], animated inAnimated: Bool) {
        self.engine.update(sections: inSections, animated: inAnimated)
    }

    public func update(rows inRows: [T], section inSectionID: String, animated inAnimated: Bool) {
        self.engine.update(rows: inRows, section: inSectionID, animated: inAnimated)
    }

    // MARK: updating, convenience

    public func deleteItems(_ items: [T], animated: Bool = true) {
        self.engine.deleteItems(items, animated: animated)
    }

    // MARK: -

    public func dequeueReusableCell(withIdentifier reuseIdentifier: String, sectionID inSectionID: String, item inItem: T) -> UITableViewCell? {
        guard let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    }

    public func reloadAll() {
        self.tableView.reloadData()
    }

    public func reload(sectionID inSectionID: String) {
        if let sectionID = self.engine.sectionIndex(forSectionID: inSectionID) {
            self.tableView.reloadSections(IndexSet(integer: sectionID), with: UITableViewRowAnimation.automatic)
        }
    }

    public func reload(sectionID inSectionID: String, item inItem: T) {
        if let indexPath = self.engine.indexPath(forSectionID: inSectionID, rowItem: inItem) {
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        }
    }

    // MARK: -
    // MARK: UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        let sections = self.engine.sections()
        self.engine.logWhenVerbose(message: "TableDataSource.numberOfSectionsInTableView() -> \(sections.count)")
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = self.engine.numberOfRows(forSectionIndex: section)
        self.engine.logWhenVerbose(message: "tableView(,numberOfRowsInSection: \(section)) -> \(numberOfRows)")
        return numberOfRows
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        self.engine.logWhenVerbose(message:"tableView(,cellForRowAtIndexPath: \(indexPath))")
        guard let location = self.engine.location(forIndexPath: indexPath) else {
            preconditionFailure("rows not found")
        }

        return self.cellForLocation(location)
    }

    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let canActuallyMove = self.canMoveToLocation else {
            // callback not implemented, so... no, you can't!
            return false
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return false
        }

        return canActuallyMove(location)
    }

    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.engine.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }

    public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {

        guard let callback = self.targetMovedItemFromLocationToProposedLocation else {
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
        let actualDestination = callback(fromLocation, toLocation)

        // check whether actual destination is OK
        if let item = actualDestination.item, let indexPath = self.engine.indexPath(forSectionID: actualDestination.sectionID, rowItem: item) {
            return indexPath
        }

        guard let sectionIndex = self.engine.sectionIndex(forSectionID: actualDestination.sectionID) else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }

        let rows = self.engine.rows(forSection: actualDestination.sectionID)
        if  rows.count != 0 {
            return IndexPath(row: rows.count-1, section: sectionIndex)

        } else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }
    }

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        switch editingStyle {
        case .delete:
            guard let location = self.engine.location(forIndexPath: indexPath) else {
                return
            }

            if let callback = self.willDeleteAtLocation {
                callback(location)
            }

            var rows = self.engine.rows(forSection: location.sectionID)
            if rows.count != 0 {
                rows.remove(at: indexPath.row)
                self.engine.update(rows: rows, section: location.sectionID, animated: true)
            }

            if let callback = self.didDeleteItem {
                callback(location.item)
            }

            // HACK? Is this really the right thing to do here conceptually???
            if let callback = self.engine.didChangeSectionIDs {
                let sectionID = location.sectionID
                let rows = self.engine.rows(forSection: sectionID)
                callback([sectionID: rows])
            }

        case .insert:
            print(".insert ????")

        case .none:
            print(".none ????")
        }
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return false
        }

        guard let callback = self.canEditAtLocation else {
            return false
        }

        return callback(location)
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionID = self.engine.sections().optionalElement(index: section) else {
            self.engine.warn(message: "section not found at index \(section)")
            return nil
        }

        guard let callback = self.sectionHeaderTitleForSectionID else {
            return nil
        }

        return callback(sectionID)

    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionID = self.engine.sections().optionalElement(index: section) else {
            self.engine.warn(message: "section not found at index \(section)")
            return nil
        }

        guard let callback = self.sectionFooterTitleForSectionID else {
            return nil
        }

        return callback(sectionID)
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let callback = self.didSelectLocation else {
            return
        }

        guard let location = self.engine.location(forIndexPath: indexPath) else {
            return
        }

        callback(location)
    }
}

// swiftlint:enable file_length
