// swiftlint:disable line_length
// swiftlint:disable file_length
//
//  BaseDataSourceTests.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 28.01.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
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

import XCTest
@testable import FURRDataSource

class MockTVItem: DataItem {
    let identifier: String

    class func mockTVItems(identifiers inIdentifiers: [String]) -> [MockTVItem] {
        return inIdentifiers.map { return MockTVItem(identifier:$0) }
    }

    init (identifier: String) {
        self.identifier = identifier
    }
}

func == (lhs: MockTVItem, rhs: MockTVItem) -> Bool {
    return (lhs.identifier == rhs.identifier)
}

func < (lhs: MockTVItem, rhs: MockTVItem) -> Bool {
    return (lhs.identifier < rhs.identifier)
}

func cellForSectionID(inSectionID: String, item inItem: MockTVItem, tableView inTableView: UITableView) -> UITableViewCell {
    let rowID = inItem.identifier
    let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: inSectionID+rowID)
    cell.textLabel?.text = inSectionID
    cell.detailTextLabel?.text = rowID
    return cell
}

class BaseDataSourceTests: XCTestCase {

    // MARK: - helper
    func sections() -> [String] {
        XCTFail("needs to be overridden")
        return []
    }

    func rows(forSection: String) -> [MockTVItem] {
        XCTFail("needs to be overridden")
        return []
    }

    func setFunc(fail inFailFunc: @escaping (String) -> Void) {
        XCTFail("needs to be overridden")
    }
    func setFunc(warn inWarnFunc: @escaping (String) -> Void) {
        XCTFail("needs to be overridden")
    }
    func setDidChangeSectionIDsFunc(didChangeFunc inDidChangeFunc: @escaping (([String: [MockTVItem]]) -> Void)) {
        XCTFail("needs to be overridden")
    }

    // MARK: - given

    func givenDelegateAndDataSource() {
        XCTFail("needs to be overridden")
    }

    func givenDiffsAreCleared() {
        XCTFail("needs to be overridden")
    }

    func givenWillAllowSelect(sectionID inSectionID: String, rowID inRowID: String) {
        XCTFail("needs to be overridden")
    }

    func givenCanMoveItem(atSectionID inSectionID: String, rowID inRowID: String) {
        XCTFail("needs to be overridden")
    }

    func givenExpectRowIDsAfterMove(rowIDs inRowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        XCTFail("needs to be overridden")
    }

    // MARK: - when
    final func whenUpdatingSectionIDs(_ inSectionIDs: [String]) {
        self.whenUpdating(sectionIDs: inSectionIDs)
    }

    func whenUpdating(sectionIDs inSectionIDs: [String]) {
        XCTFail("needs to be overridden")
    }

    func whenUpdating(rowsWithIdentifiers inRows: [String], sectionID: String) {
        XCTFail("needs to be overridden")
    }

    func whenSelecting(row inRow: Int, section: Int) {
        XCTFail("needs to be overridden")
    }

    func whenMoving(sourceRow inSourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
        XCTFail("needs to be overridden")
    }

    // MARK: - then

    func thenNumberOfSectionsIs(numberOfSections inNumberOfSections: Int) {
        XCTFail("needs to be overridden")
    }

    func thenNumberOfRowsIs(numberOfRows inNumberOfRows: Int, sectionIndex: Int) {
        XCTFail("needs to be overridden")
    }

    func thenInsertionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        XCTFail("needs to be overridden")
    }

    func thenDeletionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        XCTFail("needs to be overridden")
    }

    func thenCanSelectHandlerWasCalled() {
        XCTFail("needs to be overridden")
    }

    func thenCanMoveItem(atRow row: Int, section: Int, canMove: Bool) {
        XCTFail("needs to be overridden")
    }

    // MARK: - test

    func baseTestDataSourceSections() {
        self.givenDelegateAndDataSource()

        var sections = ["a", "b", "c"]
        self.whenUpdatingSectionIDs(sections)
        self.thenNumberOfSectionsIs(numberOfSections: 3)
        XCTAssert(["a", "b", "c"] == self.sections())

        // test whether the data source hands out copies
        sections = ["a", "b", "c", "d"]
        XCTAssert(sections != self.sections())

        self.whenUpdatingSectionIDs(["a", "d", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdatingSectionIDs(["a", "d", "c", "e"])
        self.thenNumberOfSectionsIs(numberOfSections: 4)

        self.whenUpdatingSectionIDs([])
        self.thenNumberOfSectionsIs(numberOfSections: 0)

        var didFail = false
        self.setFunc(fail: { (_) -> Void in didFail = true })

        self.whenUpdatingSectionIDs(["a", "a", "a"])
        XCTAssert(didFail)
    }

    func baseTestDataSourceRows() {
        self.givenDelegateAndDataSource()

        var didWarn = false
        self.setFunc(warn: { (_: String?) -> Void in
            didWarn = true
        })

        // trying to update non-existing section
        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")
        XCTAssert(didWarn)

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")

        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [[0, 0], [1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [])
        XCTAssert(MockTVItem.mockTVItems(identifiers: ["0", "1", "2"]) == (self.rows(forSection: "a")))

        self.givenDiffsAreCleared()

        self.whenUpdating(rowsWithIdentifiers: ["0", "2", "3"], sectionID: "a")
        self.thenNumberOfSectionsIs(numberOfSections: 3)
        self.thenInsertionRowsSectionsAre(indexPaths: [[2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0]])

        var didFail = false
        self.setFunc(fail: { (_) -> Void in didFail = true })
        self.whenUpdating(rowsWithIdentifiers: ["0", "0", "0"], sectionID: "a")
        XCTAssert(didFail)
    }

    func baseTestDataSourceRowsDelete() {
        self.givenDelegateAndDataSource()

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdating(rowsWithIdentifiers: ["0", "5", "4", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 4, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [[1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0]])

        self.givenDiffsAreCleared()

        print("")

        self.whenUpdating(rowsWithIdentifiers: ["0", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 2, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0], [2, 0]])

        self.givenDiffsAreCleared()

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2", "3", "4", "5"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdating(rowsWithIdentifiers: ["0", "2", "4"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0], [3, 0], [5, 0]])
    }

    func baseTestDataSourceWhenCompletelyEmpty() {
        self.givenDelegateAndDataSource()

        self.thenNumberOfSectionsIs(numberOfSections: 0)

        // note: asking for the number of rows in section 0 would result in a fail as we don't have a sectionID.
    }

    func baseTestDidSelect() {
        self.givenDelegateAndDataSource()
        self.givenWillAllowSelect(sectionID: "a", rowID: "1")

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)

        self.whenSelecting(row: 1, section: 0)
        self.thenCanSelectHandlerWasCalled()
    }

    func baseTestCanMove() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItem(atSectionID: "a", rowID: "2")

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)

        self.thenCanMoveItem(atRow: 2, section: 0, canMove: true)
        self.thenCanMoveItem(atRow: 1, section: 0, canMove: false)
    }

    func baseTestMove() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItem(atSectionID: "a", rowID: "2")
        self.givenExpectRowIDsAfterMove(rowIDs: ["0", "2", "1"], forSectionID: "a", withSectionCount: 1)

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)

        self.whenMoving(sourceRow: 2, sourceSection: 0, toRow: 1, toSection: 0)
    }

    func baseTestMoveBeyondLastItem() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItem(atSectionID: "a", rowID: "1")
        self.givenExpectRowIDsAfterMove(rowIDs: ["0", "2", "1"], forSectionID: "a", withSectionCount: 1)

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)

        self.whenMoving(sourceRow: 1, sourceSection: 0, toRow: 3, toSection: 0)
    }

    func baseTestMoveAcrossSections() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItem(atSectionID: "a", rowID: "3")

        self.whenUpdatingSectionIDs(["a", "b", "c"])

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2", "3"], sectionID: "a")
        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "b")

        let expectation = self.expectation(description: "sections changed callback")

        self.setDidChangeSectionIDsFunc(didChangeFunc: { (inSectionIDs: [String: [MockTVItem]]) -> Void in
            expectation.fulfill()
            XCTAssert(inSectionIDs.count == 2, "should be only two sections")

            guard let rowsA = inSectionIDs["a"] else {
                XCTFail("no rows for a?")
                return
            }

            let mappedIDsA = rowsA.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDsA == ["0", "1", "2"])

            guard let rowsB = inSectionIDs["b"] else {
                XCTFail("no rows for b?")
                return
            }

            let mappedIDsB = rowsB.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDsB == ["0", "1", "3", "2"])
        })

        self.whenMoving(sourceRow: 3, sourceSection: 0, toRow: 2, toSection: 1)

        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
