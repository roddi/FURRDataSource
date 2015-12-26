//
//  DataSourceEngineTests.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 26.12.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import XCTest

class DataSourceEngineTests: XCTestCase {

    var engine = DataSourceEngine<MockTVItem>()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.engine = DataSourceEngine<MockTVItem>()
        self.engine.beginUpdates = {}
        self.engine.endUpdates = {}
        self.engine.deleteSections = { indexSet in }
        self.engine.insertSections = { indexSet in }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDataSourceSections() {

        var sections = ["a","b","c"]
        self.engine.updateSections(sections, animated: true)
        self.thenNumberOfSectionsIs(3)
        XCTAssert(sections == (self.engine.sections()))

        // test whether it's actually const
        sections = ["a","b","c","d"]
        XCTAssert(sections != (engine.sections()))

        self.engine.updateSections(["a","d","c"], animated: true)
        self.thenNumberOfSectionsIs(3)

        self.engine.updateSections(["a","d","c","e"], animated: true)
        self.thenNumberOfSectionsIs(4)

        self.engine.updateSections([], animated: true)
        self.thenNumberOfSectionsIs(0)

        var didFail = false
        self.engine.fail = { (msg) -> Void in didFail = true }

        self.engine.updateSections(["a","a","a"], animated: true)
        XCTAssert(didFail)
    }

    func testDataSourceRows() {
        var didWarn = false
        self.engine.warn = { (message: String?) -> Void in
            didWarn = true
        }

        // trying to update non-existing section
        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        XCTAssert(didWarn)

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")

        self.thenNumberOfRowsIs(3, sectionIndex: 0)
        self.thenInsertionRowsSectionsAre([[0, 0], [1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre([])
        XCTAssert(MockTVItem.mockTVItemsForIdentifiers(["0","1","2"]) == (self.engine.rowsForSection("a")))

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","2","3"], sectionID: "a")
        self.thenNumberOfSectionsIs(3)
        self.thenInsertionRowsSectionsAre([[2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        var didFail = false
        self.engine.fail = { (msg) -> Void in didFail = true }
        self.whenUpdatingRowsWithIdentifiers(["0","0","0"], sectionID: "a")
        XCTAssert(didFail)
    }

    // MARK: - given

    func givenDiffsAreCleared() {
//        tableView.deletionRowIndexPaths = []
//        tableView.insertionRowIndexPaths = []
//        tableView.insertionSectionIndexSet = NSMutableIndexSet()
//        tableView.deletionSectionIndexSet = NSMutableIndexSet()
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
        XCTAssert(engine.tableView(tableView, numberOfRowsInSection: sectionIndex) == numberOfRows)
    }

    func thenInsertionRowsSectionsAre(indexPaths: [[Int]]) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = indexPaths.map(indexListMapper)

        XCTAssert(tableView.insertionRowIndexPaths == realIndexPaths)
    }

    func thenDeletionRowsSectionsAre(indexPaths: [[Int]]) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = indexPaths.map(indexListMapper)

        XCTAssert(tableView.deletionRowIndexPaths == realIndexPaths)
    }

}
