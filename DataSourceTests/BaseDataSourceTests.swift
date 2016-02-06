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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - helper
    func sections() -> [String] {
        XCTFail("needs to be overridden")
        return []
    }

    func setFailFunc(_: (String) -> Void) {
        XCTFail("needs to be overridden")
    }

    // MARK: - given

    func givenDelegateAndDataSource() {
        XCTFail("needs to be overridden")
    }

    // MARK: - when

    func whenUpdatingSectionIDs(inSectionIDs: Array<String>) {
        XCTFail("needs to be overridden")
    }

    // MARK: - then

    func thenNumberOfSectionsIs(numberOfSections: Int) {
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


}
