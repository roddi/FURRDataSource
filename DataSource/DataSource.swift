//
//  DataSource.swift
//  DBDB
//
//  Created by Ruotger Deecke on 27.07.15.
//  Copyright © 2015 Deecke,Roddi. All rights reserved.
//
// swiftlint:disable file_length

import UIKit
import FURRExtensions
import FURRDiff

enum DataSourceReportingLevel {
    case PreCondition /// always crashes
    case Assert /// crashes debug versions otherwise silent, this is the default
    case Print /// prints in debug versions otherwise silent.
    case Silent /// always silently ignores everything
}

public protocol DataItem: Equatable {
    var identifier: String { get }
}

public struct Location<T> {
    public let sectionID: String
    public let item:T
}

public struct LocationWithOptionalItem<T> {
    public let sectionID: String
    public let item: T?

    public init (sectionID  inSectionID: String, item inItem: T?) {
        self.sectionID = inSectionID
        self.item = inItem
    }
}

public class DataSource <T where T: DataItem> : NSObject, UITableViewDelegate, UITableViewDataSource {

    private let tableView: UITableView
    private let engine: DataSourceEngine<T>

    // logging / failing
    func setFailFunc(failFunc: (String) -> Void) {
        self.engine.fail = failFunc
    }
    func setWarnFunc(warnFunc: (String) -> Void) {
        self.engine.warn = warnFunc
    }
    func setReportingLevel(level: DataSourceReportingLevel) {
        self.engine.reportingLevel = level
    }

    // trampoline methods
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

    public init(tableView inTableView: UITableView, cellForLocationCallback inCellForLocation:(inLocation:Location<T>) -> UITableViewCell) {
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

    public func dequeueReusableCellWithIdentifier(identifier: String, sectionID inSectionID: String, item inItem: T) -> UITableViewCell? {
        guard let indexPath = self.engine.indexPathForSectionID(inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
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

    // MARK: - private
/*
    private func indexPathForSectionID(inSectionID: String, rowItem inRowItem: T) -> NSIndexPath? {
        guard let sectionIndex = sectionIndexForSectionID(inSectionID) else {
            return nil
        }

        guard let rows: Array<T> = self.rowsBySectionID[inSectionID] else {
            return nil
        }

        guard let rowIndex = rows.indexOf(inRowItem) else {
            return nil
        }

        return NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
    }

    private func sectionIndexForSectionID(inSectionID: String) -> Int? {
        guard self.sectionsInternal.contains(inSectionID) else {
            return nil
        }

        return self.sectionsInternal.indexOf(inSectionID)
    }

    private func sectionIDAndRowsForSectionIndex(inSectionIndex: Int) -> (String, Array<T>)? {
        guard let sectionID = self.sectionsInternal.optionalElementAtIndex(inSectionIndex) else {
            print("section not found at index \(inSectionIndex)")
            return nil
        }

        guard let rowArray: Array<T> = self.rowsBySectionID[sectionID] else {
            print("row array not found for sectionID \(sectionID)")
            return nil
        }

        return (sectionID, rowArray)
    }

    private func locationForIndexPath(inIndexPath: NSIndexPath) -> Location<T>? {
        guard let (sectionID, item) = self.sectionIDAndItemForIndexPath(inIndexPath) else {
            return nil
        }

        let location = Location(sectionID: sectionID, item: item)
        return location
    }

    private func locationWithOptionalItemForIndexPath(inIndexPath: NSIndexPath) -> LocationWithOptionalItem<T>? {
        guard let (sectionID, rows) = self.sectionIDAndRowsForSectionIndex(inIndexPath.section) else {
            print("sectionID/row not found!")
            return nil
        }

        let item = rows.optionalElementAtIndex(inIndexPath.row)
        let location = LocationWithOptionalItem(sectionID: sectionID, item: item)

        return location
    }
*/
    // MARK: - UITableViewDataSource

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = self.engine.sections()
        return sections.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection inSection: Int) -> Int {
        guard let sectionID = self.engine.sections().optionalElementAtIndex(inSection) else {
            self.engine.failWithMessage("no section at index '\(inSection)'")
            return 0
        }

        let rows = self.engine.rowsForSection(sectionID)
        return rows.count
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

extension DataSource {
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
