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
@testable import FURRDataSource

class DataSourceEngineTests: XCTestCase {

    var engine = DataSourceEngine<MockTVItem>()

    var insertionRowIndexPaths: [IndexPath] = []
    var deletionRowIndexPaths: [IndexPath] = []
    var insertionSectionIndexSet: IndexSet = IndexSet()
    var deletionSectionIndexSet: IndexSet = IndexSet()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.engine = DataSourceEngine<MockTVItem>()
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in self.deletionSectionIndexSet = indexSet }
        self.engine.insertSections = { indexSet in self.insertionSectionIndexSet = indexSet }
        self.engine.insertRowsAtIndexPaths = { indexPathArray in
            self.insertionRowIndexPaths.append(contentsOf: indexPathArray)
        }
        self.engine.deleteRowsAtIndexPaths = { indexPathArray in
            self.deletionRowIndexPaths.append(contentsOf: indexPathArray)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDataSourceSections() {

        var sections = ["a", "b", "c"]
        self.engine.update(sections: sections, animated: true)
        self.thenNumberOfSectionsIs(numberOfSections: 3)
        XCTAssert(sections == (self.engine.sections()))

        // test whether it's actually const
        sections = ["a", "b", "c", "d"]
        XCTAssert(sections != (engine.sections()))

        self.engine.update(sections: ["a", "d", "c"], animated: true)
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.engine.update(sections: ["a", "d", "c", "e"], animated: true)
        self.thenNumberOfSectionsIs(numberOfSections: 4)

        self.engine.update(sections: [], animated: true)
        self.thenNumberOfSectionsIs(numberOfSections: 0)

        var didFail = false
        self.engine.fail = { (msg) -> Void in didFail = true }

        self.engine.update(sections: ["a", "a", "a"], animated: true)
        XCTAssert(didFail)
    }

    func testDataSourceRows() {
        var didWarn = false
        self.engine.warn = { (message: String?) -> Void in
            didWarn = true
        }

        // trying to update non-existing section
        self.whenUpdatingRows(identifiers: ["0", "1", "2"], sectionID: "a")
        XCTAssert(didWarn)

        self.whenUpdatingSections(withIDs: ["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdatingRows(identifiers: ["0", "1", "2"], sectionID: "a")

        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [[0, 0], [1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [])
        XCTAssert(MockTVItem.mockTVItems(identifiers: ["0", "1", "2"]) == (self.engine.rows(forSection: "a")))

        self.givenDiffsAreCleared()

        self.whenUpdatingRows(identifiers: ["0", "2", "3"], sectionID: "a")
        self.thenNumberOfSectionsIs(numberOfSections: 3)
        self.thenInsertionRowsSectionsAre(indexPaths: [[2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0]])

        var didFail = false
        self.engine.fail = { (msg) -> Void in didFail = true }
        self.whenUpdatingRows(identifiers: ["0", "0", "0"], sectionID: "a")
        XCTAssert(didFail)
    }

    func testIndexPathByLocation() {
        self.whenUpdatingSections(withIDs: ["a", "b", "c"])
        self.whenUpdatingRows(identifiers: ["0", "1", "2"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.thenIndexPathIs(indexPath: IndexPath(indexes: [0, 0]), forLocation: Location(sectionID: "a", item: MockTVItem(identifier: "0")))
        self.thenIndexPathIs(indexPath: IndexPath(indexes: [0, 1]), forLocation: Location(sectionID: "a", item: MockTVItem(identifier: "1")))
        self.thenIndexPathIs(indexPath: IndexPath(indexes: [0, 2]), forLocation: Location(sectionID: "a", item: MockTVItem(identifier: "2")))
    }

    func testDataSourceRowsDelete() {
        self.whenUpdatingSections(withIDs: ["a", "b", "c"])
        self.thenNumberOfSectionsIs(numberOfSections: 3)

        self.whenUpdatingRows(identifiers: ["0", "1", "2"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdatingRows(identifiers: ["0", "5", "4", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 4, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [[1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0]])

        self.givenDiffsAreCleared()

        print("")

        self.whenUpdatingRows(identifiers: ["0", "2"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 2, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0], [2, 0]])

        self.givenDiffsAreCleared()

        self.whenUpdatingRows(identifiers: ["0", "1", "2", "3", "4", "5"], sectionID: "a")
        self.givenDiffsAreCleared()

        self.whenUpdatingRows(identifiers: ["0", "2", "4"], sectionID: "a")
        self.thenNumberOfRowsIs(numberOfRows: 3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre(indexPaths: [])
        self.thenDeletionRowsSectionsAre(indexPaths: [[1, 0], [3, 0], [5, 0]])
    }

    func testDataSourceWhenCompletelyEmpty() {

        self.thenNumberOfSectionsIs(numberOfSections: 0)

        // note: asking for the number of rows in section 0 would result in a fail as we don't have a sectionID.
    }

    // MARK: - given

    func givenDiffsAreCleared() {
        self.deletionRowIndexPaths = []
        self.insertionRowIndexPaths = []
        self.insertionSectionIndexSet = IndexSet()
        self.deletionSectionIndexSet = IndexSet()
    }

    // MARK: - when

    func whenUpdatingSections(withIDs inSectionIDs: [String]) {
        self.engine.update(sections: inSectionIDs, animated: true)
    }

    func whenUpdatingRows(identifiers rowIdentifiers: [String], sectionID: String) {
        self.engine.update(rows: MockTVItem.mockTVItems(identifiers: rowIdentifiers), section: sectionID, animated: true)
    }

    // MARK: - then

    func thenNumberOfSectionsIs(numberOfSections inNumberOfSections: Int) {
        XCTAssert(engine.sections().count == inNumberOfSections, "...")
    }

    func thenNumberOfRowsIs(numberOfRows inNumberOfRows: Int, sectionIndex: Int) {
        if let sectionIDAndRows = engine.sectionIDAndRows(forSectionIndex: sectionIndex) {
            XCTAssert(sectionIDAndRows.1.count == inNumberOfRows)
        } else {
            XCTFail()
        }
    }

    func thenIndexPathIs(indexPath: IndexPath?, forLocation: Location<MockTVItem>) {
        XCTAssertEqual(indexPath, engine.indexPath(forLocation: forLocation))
    }

    func thenInsertionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssert(self.insertionRowIndexPaths == realIndexPaths)
    }

    func thenDeletionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssert(self.deletionRowIndexPaths == realIndexPaths)
    }

}
