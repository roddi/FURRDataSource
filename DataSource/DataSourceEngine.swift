// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length
// swiftlint:disable cyclomatic_complexity

// for swift 3 this is in conflict with what the compiler warns about
// swiftlint:disable conditional_binding_cascade

//
//  DataSourceEngine.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 26.12.15.
//  Copyright © 2015-2016 Ruotger Deecke. All rights reserved.
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

import Foundation
import FURRDiff

public enum DataSourceReportingLevel {
    case preCondition /// always crashes
    case assert /// crashes debug versions otherwise silent, this is the default
    case print /// prints in debug versions otherwise silent.
    case verbose /// prints a lot of stuff.
    case silent /// always silently ignores everything
}

internal class DataSourceEngine <T> where T: DataItem {
    private var sectionsInternal: [String] = []
    private var rowsBySectionID: [String: [T]] = Dictionary()

    // MARK: - delegate blocks
    var beginUpdates: (() -> Void)?
    var endUpdates: (() -> Void)?

    var deleteSections: ((IndexSet) -> Void)?
    var insertSections: ((IndexSet) -> Void)?

    var didChangeSectionIDs: (([String: [T]]) -> Void)?
    var deleteRowsAtIndexPaths: (([IndexPath]) -> Void)?
    var insertRowsAtIndexPaths: (([IndexPath]) -> Void)?

    internal var fail: ((String) -> Void )?
    internal var warn: ((String) -> Void )?
    internal var reportingLevel: DataSourceReportingLevel = .assert

    // MARK: - querying

    // MARK: by id

    func sections() -> [String] {
        let sections = self.sectionsInternal
        return sections
    }

    func rows(forSection section: String) -> [T] {
        if let rows = self.rowsBySectionID[section] {
            return rows
        } else {
            return []
        }
    }

    // MARK: by location

    func indexPath(forLocation location: Location<T>) -> IndexPath? {
        return indexPath(forSectionID: location.sectionID, rowItem: location.item)
    }

    // MARK: by index

    func numberOfRows(forSectionIndex index: Int) -> Int {
        guard let sectionID = self.sections().optionalElement(index: index) else {
            self.fail(message: "no section at index '\(index)'")
            return 0
        }

        let rows = self.rows(forSection: sectionID)
        return rows.count
    }

    func sectionIDAndItem(forIndexPath indexPath: IndexPath) -> (String, T)? {
        let sectionIndex: Int = indexPath.section
        guard let (sectionID, rowArray) = self.sectionIDAndRows(forSectionIndex: sectionIndex) else {
            return nil
        }

        guard let item = rowArray.optionalElement(index: indexPath.row) else {
            print("item not found at index \(indexPath.row) for sectionID \(sectionID)")
            return nil
        }

        return (sectionID, item)
    }

    func sectionIDAndRows(forSectionIndex sectionIndex: Int) -> (String, [T])? {
        guard let sectionID = self.sectionsInternal.optionalElement(index: sectionIndex) else {
            print("section not found at index \(sectionIndex)")
            return nil
        }

        guard let rowArray: [T] = self.rowsBySectionID[sectionID] else {
            print("row array not found for sectionID \(sectionID)")
            return nil
        }

        return (sectionID, rowArray)
    }

    // MARK: by index path

    func location(forIndexPath indexPath: IndexPath) -> Location<T>? {
        guard let (sectionID, item) = self.sectionIDAndItem(forIndexPath: indexPath) else {
            return nil
        }

        let location = Location(sectionID: sectionID, item: item)
        return location
    }


    // MARK: - updating
    func update(sections sectionsToUpdate: [String], animated inAnimated: Bool) {

        if sectionsToUpdate.containsDuplicatesFast() {
            self.fail(message: "duplicate section ids - FURRDataSource will be confused by this later on so it is not permitted. Severity: lethal, sorry, nevertheless have a good evening!")
            return
        }

        guard
            let beginUpdatesFunc = self.beginUpdates,
            let endUpdatesFunc = self.endUpdates,
            let deleteSectionsFunc = self.deleteSections,
            let insertSectionsFunc = self.insertSections else {
                self.fail(message: "At least one of the required callback funcs of DataSourceEngine is nil. Severity: lethal, sorry, nevertheless have a good evening!")
                return
        }

        let diffs = diffBetweenArrays(arrayA: self.sectionsInternal, arrayB: sectionsToUpdate)

        var index = 0
        beginUpdatesFunc()
        for diff in diffs {
            switch diff.operation {
            case .delete:
                for _ in diff.array {
                    self.sectionsInternal.remove(at: index)
                    deleteSectionsFunc(IndexSet(integer: index))
                }
            case .insert:
                for string in diff.array {
                    self.sectionsInternal.insert(string, at: index)
                    insertSectionsFunc(IndexSet(integer: index))
                    index += 1
                }
            case .equal:
                index += diff.array.count
            }
        }
        endUpdatesFunc()

        assert(self.sectionsInternal == sectionsToUpdate, "should be equal now")
    }

    func update(rows rowsToUpdate: [T], section inSectionID: String, animated inAnimated: Bool) {
        guard let sectionIndex = self.sectionIndex(forSectionID: inSectionID) else {
            self.warn(message: "sectionID does not exists. Severity: non lethal but update will fail and data source remains unaltered.")
            return
        }

        if rowsToUpdate.containsDuplicates() {
            self.fail(message: "Supplied rows contain duplicates. This will confuse FURRDataSource later on. Severity: lethal, sorry.")
            return
        }

        guard
            let beginUpdatesFunc = self.beginUpdates,
            let endUpdatesFunc = self.endUpdates,
            let deleteRowsAtIndexPathsFunc = self.deleteRowsAtIndexPaths,
            let insertRowsAtIndexPathsFunc = self.insertRowsAtIndexPaths else {
                self.fail(message: "At least one of the required callback funcs of DataSourceEngine is nil. Severity: lethal, sorry, nevertheless have a good evening!")
                return
        }

        let existingRows: [T] = self.rowsBySectionID[inSectionID] ?? []

        var newRows: [T] = existingRows

        let newIdentifiers = rowsToUpdate.map({ (inDataSourceItem) -> String in
            return inDataSourceItem.identifier
        })
        let existingIdentifiers = existingRows.map({ (inDataSourceItem) -> String in
            return inDataSourceItem.identifier
        })

        let diffs = diffBetweenArrays(arrayA: existingIdentifiers, arrayB: newIdentifiers)

        beginUpdatesFunc()
        var rowIndex = 0
        var deleteRowIndex = 0
        for diff in diffs {
            switch diff.operation {
            case .delete:
                for _ in diff.array {
                    newRows.remove(at: rowIndex)
                    let indexPath = IndexPath(row: deleteRowIndex, section: sectionIndex)
                    deleteRowsAtIndexPathsFunc([indexPath])
                    deleteRowIndex += 1
                }
            case .insert:
                for rowID in diff.array {
                    // find index of new row
                    let findBlock = { (inDataSourceItem: T) -> Bool in
                        return rowID == inDataSourceItem.identifier
                    }

                    let rowIDIndex = rowsToUpdate.index(where: findBlock)
                    if let actualIndex = rowIDIndex {
                        let newRow = rowsToUpdate[actualIndex]
                        newRows.insert(newRow, at: rowIndex)
                        let indexPath = [IndexPath(row: rowIndex, section: sectionIndex)]
                        insertRowsAtIndexPathsFunc(indexPath)
                        rowIndex += 1
                    } else {
                        print("index not found for rowID '\(rowID)'")
                    }
                }

            case .equal:
                rowIndex += diff.array.count
                deleteRowIndex += diff.array.count
            }
        }
        self.rowsBySectionID[inSectionID] = newRows
        endUpdatesFunc()

        assert(newRows == rowsToUpdate, "must be equal")
    }

    // MARK: updating, convenience

    public func deleteItems(_ items: [T], animated: Bool = true) {
        let identifiers = items.map { $0.identifier }
        let allSections = sections()
        for section in allSections {
            let sectionItems = rows(forSection: section)
            let filteredItems = sectionItems.filter({ (item: T) -> Bool in
                return !identifiers.contains(item.identifier)
            })
            update(rows: filteredItems, section: section, animated: animated)
        }
    }

    // MARK: - initiated by user

    func moveRow(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let (fromSectionID, fromItem) = self.sectionIDAndItem(forIndexPath: sourceIndexPath) else {
            print("source not found!")
            return
        }

        guard let didChangeSectionIDsFunc = self.didChangeSectionIDs else {
            self.fail(message: "At least one of the required callback funcs of DataSourceEngine is nil. Severity: lethal, sorry, nevertheless have a good evening!")
            return
        }

        var rows = self.rows(forSection: fromSectionID)
        rows.remove(at: sourceIndexPath.row)
        self.rowsBySectionID[fromSectionID] = rows

        guard let (toSectionID, toRows) = self.sectionIDAndRows(forSectionIndex: destinationIndexPath.section) else {
            print("destination section not found!")
            return
        }

        print("from \(fromSectionID)-\(fromItem.identifier) --- to \(toSectionID)-@\(destinationIndexPath.row)")

        rows = toRows
        if destinationIndexPath.row >= toRows.count {
            rows.append(fromItem)
        } else {
            rows.insert(fromItem, at: destinationIndexPath.row)
        }
        self.rowsBySectionID[toSectionID] = rows

        let sectionIDs = (fromSectionID == toSectionID) ? [fromSectionID] : [fromSectionID, toSectionID]

        var changed: [String: [T]] = Dictionary()
        for sectionID in sectionIDs {
            changed[sectionID] = self.rowsBySectionID[sectionID]
        }

        didChangeSectionIDsFunc(changed)
    }

    // MARK: - private

    func indexPath(forSectionID inSectionID: String, rowItem inRowItem: T) -> IndexPath? {
        guard let sectionIndex = sectionIndex(forSectionID: inSectionID) else {
            return nil
        }

        guard let rows: [T] = self.rowsBySectionID[inSectionID] else {
            return nil
        }

        guard let rowIndex = rows.index(of: inRowItem) else {
            return nil
        }

        return IndexPath(row: rowIndex, section: sectionIndex)
    }

    func sectionIndex(forSectionID sectionID: String) -> Int? {
        guard self.sectionsInternal.contains(sectionID) else {
            return nil
        }

        return self.sectionsInternal.index(of: sectionID)
    }

    func locationWithOptionalItem(forIndexPath indexPath: IndexPath) -> LocationWithOptionalItem<T>? {
        guard let (sectionID, rows) = self.sectionIDAndRows(forSectionIndex: indexPath.section) else {
            print("sectionID/row not found!")
            return nil
        }

        let item = rows.optionalElement(index: indexPath.row)
        let location = LocationWithOptionalItem(sectionID: sectionID, item: item)

        return location
    }

    // MARK: - handling errors

    func reportWarningAccordingToLevel(message inMessage: String) {
        switch self.reportingLevel {
        // a warning will still trigger an assertion.
        case .preCondition:
            preconditionFailure("ERROR: \(inMessage)")

        case .assert:
            assertionFailure("WARNING: \(inMessage)")
        case .print, .verbose:
            print("WARNING: \(inMessage)")
        case .silent:
            // nothing to do here
            break
        }
    }

    func fail(message inMessage: String) {
        // when there's a fail block, we fail into that block otherwise
        // we fail according to the reporting level
        if let failBlock = self.fail {
            failBlock(inMessage)
            return
        }

        preconditionFailure("FATAL ERROR: \(inMessage)")
    }

    func warn(message inMessage: String) {
        // when there's a fail block, we fail into that block otherwise
        // we fail according to the reporting level
        if let warnBlock = self.warn {
            warnBlock(inMessage)
            return
        }

        self.reportWarningAccordingToLevel(message: inMessage)
    }

    func logWhenVerbose( message: @autoclosure() -> String) {
        if self.reportingLevel == .verbose {
            print(message)
        }
    }
}
