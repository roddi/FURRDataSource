//
//  DataSource.swift
//  DBDB
//
//  Created by Ruotger Deecke on 27.07.15.
//  Copyright © 2015 Deecke,Roddi. All rights reserved.
//

import Foundation
import FURRExtensions
import FURRDiff

enum DataSourceReportingLevel {
    case PreCondition /// always crashes
    case Assert /// crashes debug versions otherwise silent, this is the default
    case Print /// prints in debug versions otherwise silent.
    case Silent /// always silently ignores everything
}

public protocol TableViewItem: Equatable {
    var identifier: String { get }
}

public struct Location<T> {
    let tableView: UITableView
    let sectionID: String
    public let item:T
}

public struct LocationWithOptionalItem<T> {
    public let tableView: UITableView
    public let sectionID: String
    public let item: T?

    public init (tableView inTableView: UITableView, sectionID  inSectionID: String, item inItem: T?) {
        self.tableView = inTableView
        self.sectionID = inSectionID
        self.item = inItem
    }
}

public class DataSource <T where T: TableViewItem> : NSObject, UITableViewDataSource, UITableViewDelegate {

    private let tableView: UITableView

    private var sections: Array<String> = []
    private var rowsBySectionID: Dictionary<String,Array<T>> = Dictionary()

    public var cell: (forLocation:Location<T>) -> UITableViewCell
    public var didSelect: ((inLocation:Location<T>) -> Void)?
    public var canMove: ((toLocation:Location<T>) -> Bool)?
    public var targetMovedItem: ((fromLocation:Location<T>, proposedLocation:LocationWithOptionalItem<T>) -> LocationWithOptionalItem<T>)?
    public var didChangeSectionIDs: ((inSectionIDs:Dictionary<String,Array<T>>) -> Void)?
    public var willDelete: ((atLocation:Location<T>) -> Void)?

    var reportingLevel: DataSourceReportingLevel = .Assert
    var printInRelease: Bool = false

    public init(tableView inTableView: UITableView, cellForLocationCallback inCellForLocation:(inLocation:Location<T>) -> UITableViewCell) {
        self.tableView = inTableView
        self.cell = inCellForLocation

        super.init()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    // MARK: - updating

    public func updateSections(inSections: Array<String>, animated inAnimated: Bool) {
        let diffs = diffBetweenArrays(arrayA: self.sections, arrayB: inSections)

        var index = 0
        self.tableView.beginUpdates()
        for diff in diffs {
            switch diff.operation {
            case .Delete:
                for _ in diff.array {
                    self.sections.removeAtIndex(index)
                    self.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                }
            case .Insert:
                for string in diff.array {
                    self.sections.insert(string, atIndex: index)
                    self.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                    index++
                }
            case .Equal:
                index += diff.array.count
            }
        }
        self.tableView.endUpdates()

        assert(self.sections == inSections, "should be equal now")
    }

    public func updateRows(inRows: Array<T>, section inSectionID: String, animated inAnimated: Bool) {
        guard let sectionIndex = self.sectionIndexForSectionID(inSectionID) else {
            return
        }

        let existingRows: [T]
        if let exRows = self.rowsBySectionID[inSectionID] {
            existingRows = exRows
        }
        else {
            existingRows = []
        }

        var newRows:Array<T> = existingRows

        let newIdentifiers = inRows.map({ (inDataSourceItem) -> String in
            return inDataSourceItem.identifier
        })
        let existingIdentifiers = existingRows.map({ (inDataSourceItem) -> String in
            return inDataSourceItem.identifier
        })

        let diffs = diffBetweenArrays(arrayA: existingIdentifiers, arrayB: newIdentifiers)

        self.tableView.beginUpdates()
        var rowIndex = 0
        for diff in diffs {
            switch diff.operation {
            case .Delete:
                for _ in diff.array {
                    newRows.removeAtIndex(rowIndex)
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: rowIndex, inSection: sectionIndex)], withRowAnimation: .Automatic)
                }
            case .Insert:
                    for rowID in diff.array {
                        // find index of new row
                        let rowIDIndex = inRows.indexOf({ (inDataSourceItem) -> Bool in
                            return rowID == inDataSourceItem.identifier
                        })

                        if let actualIndex = rowIDIndex {
                            let newRow = inRows[actualIndex]
                            newRows.insert(newRow, atIndex: rowIndex)
                            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: rowIndex, inSection: sectionIndex)], withRowAnimation: .Automatic)
                            rowIndex++
                        }
                        else {
                            print("index not found for rowID '\(rowID)'")
                        }
                    }

            case .Equal:
                rowIndex += diff.array.count
            }
        }
        self.rowsBySectionID[inSectionID] = newRows
        self.tableView.endUpdates()

        assert(newRows == inRows, "must be equal")
    }

    public func dequeueReusableCellWithIdentifier(identifier: String, sectionID inSectionID: String, item inItem: T) -> UITableViewCell? {
        guard let indexPath = indexPathForSectionID(inSectionID, rowItem: inItem) else {
            return nil
        }

        return self.tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
    }

    public func reloadAll() {
        self.tableView.reloadData()
    }

    public func reloadSectionID(inSectionID: String) {
        if let sectionID = sectionIndexForSectionID(inSectionID) {
            self.tableView.reloadSections(NSIndexSet(index: sectionID), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    public func reloadSectionID(inSectionID: String, item inItem: T) {
        if let indexPath = indexPathForSectionID(inSectionID, rowItem: inItem) {
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }

    // MARK: - private

    private func indexPathForSectionID(inSectionID: String, rowItem inRowItem: T) -> NSIndexPath? {
        guard let sectionIndex = sectionIndexForSectionID(inSectionID) else {
            return nil
        }

        guard let rows:Array<T> = self.rowsBySectionID[inSectionID] else {
            return nil
        }

        guard let rowIndex = rows.indexOf(inRowItem) else {
            return nil
        }

        return NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
    }

    private func sectionIndexForSectionID(inSectionID: String) -> Int? {
        guard self.sections.contains(inSectionID) else {
            return nil
        }

        return self.sections.indexOf(inSectionID)
    }

    private func sectionIDAndRowForSectionIndex(inSectionIndex: Int) -> (String, Array<T>)? {
        guard let sectionID = self.sections.optionalElementAtIndex(inSectionIndex) else {
            print("section not found at index \(inSectionIndex)")
            return nil
        }

        guard let rowArray:Array<T> = self.rowsBySectionID[sectionID] else {
            print("row array not found for sectionID \(sectionID)")
            return nil
        }

        return (sectionID,rowArray)
    }

    private func sectionIDAndItemForIndexPath(inIndexPath: NSIndexPath) -> (String, T)? {
        let sectionIndex: Int = inIndexPath.section
        guard let (sectionID, rowArray) = self.sectionIDAndRowForSectionIndex(sectionIndex) else {
            return nil
        }

        guard let item = rowArray.optionalElementAtIndex(inIndexPath.row) else {
            print("item not found at index \(inIndexPath.row) for sectionID \(sectionID)")
            return nil
        }

        return (sectionID,item)
    }

    // MARK: - data source

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let sections = self.sections
        return sections.count
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection inSection: Int) -> Int {
        guard let sectionID = self.sections.optionalElementAtIndex(inSection) else {
            return 0;
        }

        guard let rows = self.rowsBySectionID[sectionID] else {
            print("unknown section '\(sectionID)'")
            return 0
            //preconditionFailure("rows not found")
        }
        return rows.count
    }


    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionID = self.sections[indexPath.section]

        guard let items = self.rowsBySectionID[sectionID] else {
            preconditionFailure("rows not found")
        }

        let location:Location<T> = Location(tableView: tableView, sectionID: sectionID, item: items[indexPath.row])

        return self.cell(forLocation: location)
    }


    public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let canActuallyMove = self.canMove else {
            // callback not implemented, so... no!
            return false
        }

        guard let (sectionID, item) = self.sectionIDAndItemForIndexPath(indexPath) else {
                return false
            }

        let location:Location<T> = Location(tableView: tableView, sectionID: sectionID, item: item)

        return canActuallyMove(toLocation: location)
    }


    public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        guard let (fromSectionID, fromItem) = self.sectionIDAndItemForIndexPath(sourceIndexPath) else {
            print("source not found!")
            return
        }

        var rows = self.rowsBySectionID[fromSectionID]
        rows?.removeAtIndex(sourceIndexPath.row)
        self.rowsBySectionID[fromSectionID] = rows

        guard let (toSectionID, toRows) = self.sectionIDAndRowForSectionIndex(destinationIndexPath.section) else {
            print("destination section not found!")
            return
        }

        print("from \(fromSectionID)-\(fromItem.identifier) --- to \(toSectionID)-@\(destinationIndexPath.row)")

        rows = toRows
        if destinationIndexPath.row >= toRows.count {
            rows?.append(fromItem)
        }
        else {
            rows?.insert(fromItem, atIndex: destinationIndexPath.row)
        }
        self.rowsBySectionID[toSectionID] = rows

        let sectionIDs = (fromSectionID == toSectionID) ? [fromSectionID] : [fromSectionID,toSectionID]

        var changed:Dictionary<String,Array<T>> = Dictionary()
        for sectionID in sectionIDs {
            changed[sectionID] = self.rowsBySectionID[sectionID]
        }

        if let actuallyChanged = self.didChangeSectionIDs {
            // if the client bothered to implement the callback, we call it
            actuallyChanged(inSectionIDs: changed)
        }
    }

    public func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        guard let callback = self.targetMovedItem else {
            return proposedDestinationIndexPath
        }

        guard let (fromSectionID, fromItem) = self.sectionIDAndItemForIndexPath(sourceIndexPath) else {
            print("source not found!")
            return proposedDestinationIndexPath
        }

        let fromLocation = Location(tableView: tableView, sectionID: fromSectionID, item: fromItem)

        guard let (toSectionID, toRows) = self.sectionIDAndRowForSectionIndex(proposedDestinationIndexPath.section) else {
            print("destination section not found!")
            return proposedDestinationIndexPath
        }

        let item = toRows.optionalElementAtIndex(proposedDestinationIndexPath.row)
        let toLocation = LocationWithOptionalItem(tableView: tableView, sectionID: toSectionID, item: item)

        let actualDestination = callback(fromLocation: fromLocation, proposedLocation: toLocation)

        if let item = actualDestination.item, let indexPath = indexPathForSectionID(actualDestination.sectionID, rowItem: item) {
            return indexPath
        }

        guard let sectionIndex = self.sectionIndexForSectionID(actualDestination.sectionID) else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }

        if let rows = self.rowsBySectionID[actualDestination.sectionID] {
            return NSIndexPath(forRow: rows.count-1, inSection: sectionIndex)
        }
        else {
            print("actual destination section not found!")
            return proposedDestinationIndexPath
        }
    }

    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let (sectionID, rowItem) = self.sectionIDAndItemForIndexPath(indexPath) else {
            return
        }

        switch editingStyle {
        case .Delete:
            if let actuallyDelete = self.willDelete {
                let location:Location<T> = Location(tableView: tableView, sectionID: sectionID, item: rowItem)
                actuallyDelete(atLocation: location)
            }

        case .Insert:
            print(".Insert ????")

        case .None:
            print(".None ????")
        }
    }

    // MARK - delegate

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let actuallySelect = self.didSelect else {
            // if the client does not implement this callback...
            return
        }

        guard let (sectionID, item) = self.sectionIDAndItemForIndexPath(indexPath) else {
            return
        }

        let location:Location<T> = Location(tableView: tableView, sectionID: sectionID, item: item)
        actuallySelect(inLocation: location)
    }
}
