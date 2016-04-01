// swiftlint:disable line_length
//
//  DataSourceEngineTests.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 26.12.15.
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


import XCTest

class DataSourceEngineTests: XCTestCase {

    var engine = DataSourceEngine<MockTVItem>()

    var insertionRowIndexPaths: [NSIndexPath] = []
    var deletionRowIndexPaths: [NSIndexPath] = []
    var insertionSectionIndexSet: NSIndexSet = NSMutableIndexSet()
    var deletionSectionIndexSet: NSIndexSet = NSMutableIndexSet()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.engine = DataSourceEngine<MockTVItem>()
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in self.deletionSectionIndexSet = indexSet }
        self.engine.insertSections = { indexSet in self.insertionSectionIndexSet = indexSet }
        self.engine.insertRowsAtIndexPaths = { indexPathArray in self.insertionRowIndexPaths.appendContentsOf(indexPathArray) }
        self.engine.deleteRowsAtIndexPaths = { indexPathArray in self.deletionRowIndexPaths.appendContentsOf(indexPathArray) }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDataSourceSections() {

        var sections = ["a", "b", "c"]
        self.engine.updateSections(sections, animated: true)
        self.thenNumberOfSectionsIs(3)
        XCTAssert(sections == (self.engine.sections()))

        // test whether it's actually const
        sections = ["a", "b", "c", "d"]
        XCTAssert(sections != (engine.sections()))

        self.engine.updateSections(["a", "d", "c"], animated: true)
        self.thenNumberOfSectionsIs(3)

        self.engine.updateSections(["a", "d", "c", "e"], animated: true)
        self.thenNumberOfSectionsIs(4)

        self.engine.updateSections([], animated: true)
        self.thenNumberOfSectionsIs(0)

        var didFail = false
        self.engine.fail = { (msg) -> Void in didFail = true }

        self.engine.updateSections(["a", "a", "a"], animated: true)
        XCTAssert(didFail)
    }

    func testDataSourceRows() {
        var didWarn = false
        self.engine.warn = { (message: String?) -> Void in
            didWarn = true
        }

        // trying to update non-existing section
        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2"], sectionID: "a")
        XCTAssert(didWarn)

        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2"], sectionID: "a")

        self.thenNumberOfRowsIs(3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([[0, 0], [1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre([])
        XCTAssert(MockTVItem.mockTVItemsForIdentifiers(["0", "1", "2"]) == (self.engine.rowsForSection("a")))

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0", "2", "3"], sectionID: "a")
        self.thenNumberOfSectionsIs(3)
        self.thenInsertionRowsSectionsAre([[2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        var didFail = false
        self.engine.fail = { (msg) -> Void in didFail = true }
        self.whenUpdatingRowsWithIdentifiers(["0", "0", "0"], sectionID: "a")
        XCTAssert(didFail)
    }

    func testDataSourceRowsDelete() {
        self.whenUpdatingSectionIDs(["a", "b", "c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0", "5", "4", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(4, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([[1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        self.givenDiffsAreCleared()

        print("")

        self.whenUpdatingRowsWithIdentifiers(["0", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(2, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([])
        self.thenDeletionRowsSectionsAre([[1, 0], [2, 0]])

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2", "3", "4", "5"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0", "2", "4"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([])
        self.thenDeletionRowsSectionsAre([[1, 0], [3, 0], [5, 0]])
    }

    func testDataSourceWhenCompletelyEmpty() {

        self.thenNumberOfSectionsIs(0)

        // note: asking for the number of rows in section 0 would result in a fail as we don't have a sectionID.
    }

    // MARK: - given

    func givenDiffsAreCleared() {
        self.deletionRowIndexPaths = []
        self.insertionRowIndexPaths = []
        self.insertionSectionIndexSet = NSMutableIndexSet()
        self.deletionSectionIndexSet = NSMutableIndexSet()
    }

    // MARK: - when

    func whenUpdatingSectionIDs(inSectionIDs: Array<String>) {
        self.engine.updateSections(inSectionIDs, animated: true)
    }

    func whenUpdatingRowsWithIdentifiers(identifiers: [String], sectionID: String) {
        self.engine.updateRows(MockTVItem.mockTVItemsForIdentifiers(identifiers), section: sectionID, animated: true)
    }

    // MARK: - then

    func thenNumberOfSectionsIs(numberOfSections: Int) {
        XCTAssert(engine.sections().count == numberOfSections, "...")
    }

    func thenNumberOfRowsIs(numberOfRows: Int, sectionIndex: Int) {
        if let sectionIDAndRows = engine.sectionIDAndRowsForSectionIndex(sectionIndex) {
            XCTAssert(sectionIDAndRows.1.count == numberOfRows)
        } else {
            XCTFail()
        }
    }

    func thenInsertionRowsSectionsAre(indexPaths: [[Int]]) {
        let realIndexPaths = indexPaths.map(testHelper_indexListMapper())

        XCTAssert(self.insertionRowIndexPaths == realIndexPaths)
    }

    func thenDeletionRowsSectionsAre(indexPaths: [[Int]]) {
        let realIndexPaths = indexPaths.map(testHelper_indexListMapper())

        XCTAssert(self.deletionRowIndexPaths == realIndexPaths)
    }

}
