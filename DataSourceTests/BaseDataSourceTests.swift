// swiftlint:disable line_length
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

class MockTVItem: DataItem {
    let identifier: String

    class func mockTVItemsForIdentifiers(identifiers: [String]) -> [MockTVItem] {
        return identifiers.map { return MockTVItem(identifier:$0) }
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
    let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: inSectionID+rowID)
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

    func rowsForSection(section: String) -> [MockTVItem] {
        XCTFail("needs to be overridden")
        return []
    }

    func setFailFunc(_: (String) -> Void) {
        XCTFail("needs to be overridden")
    }

    func setWarnFunc(warnFunc: (String) -> Void) {
        XCTFail("needs to be overridden")
    }

    func setDidChangeSectionIDsFunc(didChangeFunc: ((inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void)) {
        XCTFail("needs to be overridden")
    }

    // MARK: - given

    func givenDelegateAndDataSource() {
        XCTFail("needs to be overridden")
    }

    func givenDiffsAreCleared() {
        XCTFail("needs to be overridden")
    }

    func givenWillAllowSelectInSectionID(sectionID: String, rowID inRowID: String) {
        XCTFail("needs to be overridden")
    }

    func givenCanMoveItemAtSectionID(inSectionID: String, rowID inRowID: String) {
        XCTFail("needs to be overridden")
    }

    func givenExpectRowIDsAfterMove(rowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        XCTFail("needs to be overridden")
    }

    // MARK: - when

    func whenUpdatingSectionIDs(inSectionIDs: Array<String>) {
        XCTFail("needs to be overridden")
    }

    func whenUpdatingRowsWithIdentifiers(identifiers: [String], sectionID: String) {
        XCTFail("needs to be overridden")
    }

    func whenSelectingRow(row: Int, section: Int) {
        XCTFail("needs to be overridden")
    }

    func whenMovingRow(sourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
        XCTFail("needs to be overridden")
    }

    // MARK: - then

    func thenNumberOfSectionsIs(numberOfSections: Int) {
        XCTFail("needs to be overridden")
    }

    func thenNumberOfRowsIs(numberOfRows: Int, sectionIndex: Int) {
        XCTFail("needs to be overridden")
    }

    func thenInsertionRowsSectionsAre(indexPaths: [[Int]]) {
        XCTFail("needs to be overridden")
    }

    func thenDeletionRowsSectionsAre(indexPaths: [[Int]]) {
        XCTFail("needs to be overridden")
    }

    func thenCanSelectHandlerWasCalled() {
        XCTFail("needs to be overridden")
    }

    func thenCanMoveItemAtRow(row: Int, section: Int, canMove: Bool) {
        XCTFail("needs to be overridden")
    }

    // MARK: - test

    func baseTestDataSourceSections() {
        self.givenDelegateAndDataSource()

        var sections = ["a","b","c"]
        self.whenUpdatingSectionIDs(sections)
        self.thenNumberOfSectionsIs(3)
        XCTAssert(["a","b","c"] == self.sections())

        // test whether the data source hands out copies
        sections = ["a","b","c","d"]
        XCTAssert(sections != self.sections())

        self.whenUpdatingSectionIDs(["a","d","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingSectionIDs(["a","d","c","e"])
        self.thenNumberOfSectionsIs(4)

        self.whenUpdatingSectionIDs([])
        self.thenNumberOfSectionsIs(0)

        var didFail = false
        self.setFailFunc({ (msg) -> Void in didFail = true })

        self.whenUpdatingSectionIDs(["a","a","a"])
        XCTAssert(didFail)
    }

    func baseTestDataSourceRows() {
        self.givenDelegateAndDataSource()

        var didWarn = false
        self.setWarnFunc({ (message: String?) -> Void in
            didWarn = true
        })

        // trying to update non-existing section
        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        XCTAssert(didWarn)

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")

        self.thenNumberOfRowsIs(3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([[0, 0], [1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre([])
        XCTAssert(MockTVItem.mockTVItemsForIdentifiers(["0","1","2"]) == (self.rowsForSection("a")))

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","2","3"], sectionID: "a")
        self.thenNumberOfSectionsIs(3)
        self.thenInsertionRowsSectionsAre([[2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        var didFail = false
        self.setFailFunc({ (msg) -> Void in didFail = true })
        self.whenUpdatingRowsWithIdentifiers(["0","0","0"], sectionID: "a")
        XCTAssert(didFail)
    }

    func baseTestDataSourceRowsDelete() {
        self.givenDelegateAndDataSource()

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","5","4","2"], sectionID: "a")
        self.thenNumberOfRowsIs(4, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([[1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        self.givenDiffsAreCleared()

        print("")

        self.whenUpdatingRowsWithIdentifiers(["0","2"], sectionID: "a")
        self.thenNumberOfRowsIs(2, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([])
        self.thenDeletionRowsSectionsAre([[1, 0], [2, 0]])

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","1","2","3","4","5"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","2","4"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([])
        self.thenDeletionRowsSectionsAre([[1, 0], [3, 0], [5, 0]])
    }

    func baseTestDataSourceWhenCompletelyEmpty() {
        self.givenDelegateAndDataSource()

        self.thenNumberOfSectionsIs(0)

        // note: asking for the number of rows in section 0 would result in a fail as we don't have a sectionID.
    }

    func baseTestDidSelect() {
        self.givenDelegateAndDataSource()
        self.givenWillAllowSelectInSectionID("a", rowID: "1")

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.whenSelectingRow(1, section: 0)
        self.thenCanSelectHandlerWasCalled()
    }

    func baseTestCanMove() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "2")

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.thenCanMoveItemAtRow(2, section: 0, canMove: true)
        self.thenCanMoveItemAtRow(1, section: 0, canMove: false)
    }

    func baseTestMove() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "2")
        self.givenExpectRowIDsAfterMove(["0","2","1"], forSectionID: "a", withSectionCount: 1)


        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.whenMovingRow(2, sourceSection: 0, toRow: 1, toSection: 0)
    }

    func baseTestMoveBeyondLastItem() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "1")
        self.givenExpectRowIDsAfterMove(["0","2","1"], forSectionID: "a", withSectionCount: 1)

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.whenMovingRow(1, sourceSection: 0, toRow: 3, toSection: 0)
    }

    func baseTestMoveAcrossSections() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "3")

        self.whenUpdatingSectionIDs(["a","b","c"])

        self.whenUpdatingRowsWithIdentifiers(["0","1","2","3"], sectionID: "a")
        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "b")

        let expectation = expectationWithDescription("sections changed callback")


        self.setDidChangeSectionIDsFunc({ (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
            expectation.fulfill()
            XCTAssert(inSectionIDs.count == 2, "should be only two sections")

            guard let rowsA = inSectionIDs["a"] else {
                XCTFail("no rows for a?")
                return
            }

            let mappedIDsA = rowsA.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDsA == ["0","1","2"])

            guard let rowsB = inSectionIDs["b"] else {
                XCTFail("no rows for b?")
                return
            }

            let mappedIDsB = rowsB.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDsB == ["0","1","3","2"])
        })

        self.whenMovingRow(3, sourceSection: 0, toRow: 2, toSection: 1)

        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

}
