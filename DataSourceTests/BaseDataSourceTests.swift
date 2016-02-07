//
//  BaseDataSourceTests.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 28.01.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

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

}
