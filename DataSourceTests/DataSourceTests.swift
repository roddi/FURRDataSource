//
//  DBDBDataSourceTests.swift
//  DBDB
//
//  Created by Ruotger Deecke on 28.07.15.
//  Copyright © 2015 Deecke,Roddi. All rights reserved.
//

import XCTest

class MockTVItem: TableViewItem {
    let identifier: String

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


class DataSourceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func whenDelegate() -> (UITableView,DataSource<MockTVItem>) {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), style: .Plain)
        let dataSource = DataSource<MockTVItem>(tableView: tableView) { (inLocation) -> UITableViewCell in
            cellForSectionID(inLocation.sectionID, item: inLocation.item, tableView: inLocation.tableView)
        }

        return (tableView,dataSource)
    }

    func whenDataSource(inDataSource: DataSource<MockTVItem>, canMoveItemAtSectionID inSectionID: String, rowID inRowID: String) {
        inDataSource.canMove = {(toLocation:Location<MockTVItem>) -> Bool in
            return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
        }
    }

    func whenDataSource(inDataSource:DataSource<MockTVItem>, retargetsToLocation inRetargetLocation:LocationWithOptionalItem<MockTVItem>) {
        inDataSource.targetMovedItem = { (fromLocation:Location<MockTVItem>, proposedLocation:LocationWithOptionalItem<MockTVItem>) -> LocationWithOptionalItem<MockTVItem> in
            return inRetargetLocation
        }
    }

    func whenDataSource(inDataSource: DataSource<MockTVItem>, canEditItemAtSectionID inSectionID: String, rowID inRowID: String) {
        inDataSource.canEdit = {(atLocation:Location<MockTVItem>) -> Bool in
            return atLocation.sectionID == inSectionID && atLocation.item.identifier == inRowID
        }
    }

    func whenDataSource(inDataSource:DataSource<MockTVItem>, hasSectionIDs inSectionIDs:Array<String>) {
        inDataSource.updateSections(inSectionIDs, animated: true)
    }

    func whenDataSource(inDataSource: DataSource<MockTVItem>, hasRowIDs inRowIDs: Array<String>, forSectionID inSectionID: String) {
        let rows = inRowIDs.map { (inRowID: String) -> MockTVItem in
            return MockTVItem(identifier: inRowID)
        }

        inDataSource.updateRows(rows, section: inSectionID, animated: true)
    }

    func testDataSourceSections() {
        let (tableView,dataSource) = self.whenDelegate()

        dataSource.updateSections(["a","b","c"], animated: true)
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        dataSource.updateSections(["a","d","c"], animated: true)
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        dataSource.updateSections([], animated: true)
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 0, "...")

    }

    func testDataSourceRows() {
        let (tableView,dataSource) = self.whenDelegate()

        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])

        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        dataSource.updateRows([MockTVItem(identifier:"0"),MockTVItem(identifier:"1"),MockTVItem(identifier:"2")], section: "a", animated: true)
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: 0) == 3, "...")

        dataSource.updateRows([MockTVItem(identifier:"0"),MockTVItem(identifier:"5"),MockTVItem(identifier:"4"),MockTVItem(identifier:"2")], section: "a", animated: true)
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: 0) == 4, "...")
    }

    func testDataSourceWhenCompletelyEmpty() {
        let (tableView,dataSource) = self.whenDelegate()

        let numSections = dataSource.numberOfSectionsInTableView(tableView)
        XCTAssert(numSections == 0, "...")

        let numRows = dataSource.tableView(tableView, numberOfRowsInSection: 0)
        XCTAssert(numRows == 0, "...")
    }

    func testDidSelect() {
        var didCallHandler = false
        let (tableView,dataSource) = self.whenDelegate()
        dataSource.didSelect = { (inLocation:Location<MockTVItem>) -> Void in
            XCTAssert(inLocation.sectionID == "a")
            XCTAssert(inLocation.item.identifier == "1")
            didCallHandler = true
        }

        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])

        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        dataSource.updateRows([MockTVItem(identifier:"0"),MockTVItem(identifier:"1"),MockTVItem(identifier:"2")], section: "a", animated: true)
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: 0) == 3, "...")

        dataSource.tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
        XCTAssert(didCallHandler == true)
    }

    func testCanMove() {
        let (tableView,dataSource) = self.whenDelegate()
        self.whenDataSource(dataSource, canMoveItemAtSectionID: "a", rowID: "2")

        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        dataSource.updateRows([MockTVItem(identifier:"0"),MockTVItem(identifier:"1"),MockTVItem(identifier:"2")], section: "a", animated: true)
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: 0) == 3, "...")

        XCTAssert(dataSource.tableView(tableView, canMoveRowAtIndexPath: NSIndexPath(forRow: 2, inSection: 0)) == true);
        XCTAssert(dataSource.tableView(tableView, canMoveRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0)) == false);
    }

    func testMove() {
        let (tableView,dataSource) = self.whenDelegate()
        self.whenDataSource(dataSource, canMoveItemAtSectionID: "a", rowID: "2")

        dataSource.didChangeSectionIDs = { (inSectionIDs:Dictionary<String,Array<MockTVItem>>) -> Void in
            XCTAssert(inSectionIDs.count == 1, "should be only one section")

            guard let rows = inSectionIDs["a"] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == ["0","2","1"])
        }

        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        dataSource.updateRows([MockTVItem(identifier:"0"),MockTVItem(identifier:"1"),MockTVItem(identifier:"2")], section: "a", animated: true)
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: 0) == 3, "...")

        dataSource.tableView(tableView, moveRowAtIndexPath: NSIndexPath(forRow: 2, inSection: 0), toIndexPath: NSIndexPath(forRow: 1, inSection: 0))
    }

    func testMoveBeyondLastItem() {
        let (tableView,dataSource) = self.whenDelegate()
        self.whenDataSource(dataSource, canMoveItemAtSectionID: "a", rowID: "1")

        let expectation = expectationWithDescription("sections changed callback")
        dataSource.didChangeSectionIDs = { (inSectionIDs:Dictionary<String,Array<MockTVItem>>) -> Void in
            expectation.fulfill()
            XCTAssert(inSectionIDs.count == 1, "should be only one section")

            guard let rows = inSectionIDs["a"] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == ["0","2","1"])
        }

        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == 3, "...")

        self.whenDataSource(dataSource, hasRowIDs: ["0","1","2"], forSectionID: "a")
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: 0) == 3, "...")

        dataSource.tableView(tableView, moveRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0), toIndexPath: NSIndexPath(forRow: 3, inSection: 0))

        waitForExpectationsWithTimeout(10, handler: nil)
    }


    func testMoveAcrossSections() {
        let (tableView,dataSource) = self.whenDelegate()
        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])

        self.whenDataSource(dataSource, hasRowIDs: ["0","1","2","3"], forSectionID: "a")
        self.whenDataSource(dataSource, hasRowIDs: ["0","1","2"], forSectionID: "b")

        self.whenDataSource(dataSource, canMoveItemAtSectionID: "a", rowID: "3")

        let expectation = expectationWithDescription("sections changed callback")

        dataSource.didChangeSectionIDs = { (inSectionIDs:Dictionary<String,Array<MockTVItem>>) -> Void in
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
        }

        dataSource.tableView(tableView, moveRowAtIndexPath: NSIndexPath(forRow: 3, inSection: 0), toIndexPath: NSIndexPath(forRow: 2, inSection: 1))
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testMoveWithCorrectedTarget() {
        let (tableView,dataSource) = self.whenDelegate()
        self.whenDataSource(dataSource, hasSectionIDs: ["a","b","c"])

        self.whenDataSource(dataSource, hasRowIDs: ["0","1","2","3"], forSectionID: "a")
        self.whenDataSource(dataSource, hasRowIDs: ["0","1","2"], forSectionID: "b")

        self.whenDataSource(dataSource, canMoveItemAtSectionID: "a", rowID: "3")
        self.whenDataSource(dataSource, retargetsToLocation: LocationWithOptionalItem(tableView: tableView, sectionID:"a", item:MockTVItem(identifier: "1")))

        let indexPath = dataSource.tableView(tableView, targetIndexPathForMoveFromRowAtIndexPath: NSIndexPath(forRow: 3, inSection: 0), toProposedIndexPath: NSIndexPath(forRow: 2, inSection: 0))
        XCTAssert(indexPath.section == 0)
        XCTAssert(indexPath.row == 1)

    }

    // testing: optional func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    func testCanEditItem() {
        let (tableView,dataSource) = self.whenDelegate()
        self.whenDataSource(dataSource, hasSectionIDs: ["a"])
        self.whenDataSource(dataSource, hasRowIDs: ["0","1","2","3"], forSectionID: "a")

        self.whenDataSource(dataSource, canEditItemAtSectionID: "a", rowID: "1")

        XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0)) == true)
        XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)) == false)
        XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: NSIndexPath(forRow: 1000, inSection: 0)) == false)
        XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 1000)) == false)
    }

    func testDeleteItem() {

        // XCTFail("test not yet impl'd")
    }
}
