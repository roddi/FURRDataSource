//
//  DBDBDataSourceTests.swift
//  DBDB
//
//  Created by Ruotger Deecke on 28.07.15.
//  Copyright © 2015 Deecke,Roddi. All rights reserved.
//
// swiftlint:disable file_length

import XCTest

class MockTVItem: DataItem {
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

    var tableView: MockTableView? = nil
    var dataSource: DataSource<MockTVItem>? = nil

    // MARK: - helper

    func mockTVItemsForIdentifiers(identifiers: [String]) -> [MockTVItem] {
        return identifiers.map { return MockTVItem(identifier:$0) }
    }

    // MARK: - given

    func givenDelegateAndDataSource() {
        self.tableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), style: .Plain)
        guard let tableView = self.tableView else {
            XCTFail("could not instantiate table view")
            return
        }
        self.dataSource = DataSource<MockTVItem>(tableView: tableView) { (inLocation: Location<MockTVItem>) -> UITableViewCell in
            cellForSectionID(inLocation.sectionID, item: inLocation.item, tableView: tableView)
        }
        self.dataSource?.reportingLevel = .PreCondition

        tableView.insertRowsCallback = { print("insert rows \($0)") }
        tableView.deleteRowsCallback = { print("delete rows \($0)") }
        tableView.insertSectionsCallback = { print("insert sections \($0)") }
        tableView.deleteSectionsCallback = { print("delete sections \($0)") }
        didCallDidSelectHandler = false
    }

    func givenCanMoveItemAtSectionID(inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canMove = {(toLocation: Location<MockTVItem>) -> Bool in
            return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
        }
    }

    func givenRetargetsToRowIDSectionID(rowID: String, sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        let location = LocationWithOptionalItem(sectionID: sectionID, item: MockTVItem(identifier: rowID))
        dataSource.targetMovedItem = { (fromLocation: Location<MockTVItem>, proposedLocation: LocationWithOptionalItem<MockTVItem>) -> LocationWithOptionalItem<MockTVItem> in
            return location
        }
    }

    func givenCanEditItemAtSectionID(inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canEdit = {(atLocation: Location<MockTVItem>) -> Bool in
            return atLocation.sectionID == inSectionID && atLocation.item.identifier == inRowID
        }
    }

    var didCallDidSelectHandler = false

    func givenWillAllowSelectInSectionID(sectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        didCallDidSelectHandler = false
        dataSource.didSelect = { (inLocation: Location<MockTVItem>) -> Void in
            XCTAssert(inLocation.sectionID == "a")
            XCTAssert(inLocation.item.identifier == "1")
            self.didCallDidSelectHandler = true
        }
    }

    func givenDiffsAreCleared() {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        tableView.deletionRowIndexPaths = []
        tableView.insertionRowIndexPaths = []
        tableView.insertionSectionIndexSet = NSMutableIndexSet()
        tableView.deletionSectionIndexSet = NSMutableIndexSet()
    }

    func givenExpectRowIDsAfterMove(rowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.didChangeSectionIDs = { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
            XCTAssert(inSectionIDs.count == sectionCount)

            guard let rows = inSectionIDs[sectionID] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == rowIDs)
        }

    }

    func givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles() {
        self.dataSource?.sectionHeaderTitle = { return $0 }
        self.dataSource?.sectionFooterTitle = { return $0+$0 }
    }

    // MARK: - when

    func whenUpdatingSectionIDs(inSectionIDs: Array<String>) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.updateSections(inSectionIDs, animated: true)
    }

    func whenUpdatingRowsWithIdentifiers(identifiers: [String], sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.updateRows(self.mockTVItemsForIdentifiers(identifiers), section: sectionID, animated: true)
    }

    func whenSelectingRow(row: Int, section: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        dataSource.tableView(tableView, didSelectRowAtIndexPath: indexPath)

    }

    func whenMovingRow(sourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        dataSource.tableView(tableView, moveRowAtIndexPath: NSIndexPath(forRow: sourceRow, inSection: sourceSection), toIndexPath: NSIndexPath(forRow: destinationRow, inSection: destinationSection))
    }

    // MARK: - then

    func thenNumberOfSectionsIs(numberOfSections: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == numberOfSections, "...")
    }

    func thenNumberOfRowsIs(numberOfRows: Int, sectionIndex: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: sectionIndex) == numberOfRows)
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

    func thenCanSelectHandlerWasCalled() {
        XCTAssert(self.didCallDidSelectHandler)
    }

    func thenCanMoveItemAtRow(row: Int, section: Int, canMove: Bool) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        XCTAssert(dataSource.tableView(tableView, canMoveRowAtIndexPath: NSIndexPath(forRow: row, inSection: section)) == canMove)

    }

    func thenCanEditItemAtRow(row: Int, section: Int, canMove: Bool) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: NSIndexPath(forRow: row, inSection: section)) == canMove)
    }

    func thenSectionHeaderTitle(forSectionIndex sectionIndex: Int, isString headerString: String, footerIsString footerString: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let headerTitle = dataSource.tableView(tableView, titleForHeaderInSection: sectionIndex)
        let footerTitle = dataSource.tableView(tableView, titleForFooterInSection: sectionIndex)

        XCTAssertEqual(headerString, headerTitle)
        XCTAssertEqual(footerString, footerTitle)
    }

    // MARK: - helper

    let indexListMapper = { (indexList: [Int]) -> NSIndexPath in
        if indexList.count != 2 {
            return NSIndexPath(forItem: Int.max, inSection: Int.max)
        }
        return NSIndexPath(forItem: indexList[0], inSection: indexList[1])
    }



    // MARK: - test

    func testDataSourceSections() {
        self.givenDelegateAndDataSource()

        var sections = ["a","b","c"]
        self.dataSource?.updateSections(sections, animated: true)
        self.thenNumberOfSectionsIs(3)
        XCTAssert(sections == (self.dataSource?.sections())!)

        // test whether it's actually const
        sections = ["a","b","c","d"]
        XCTAssert(sections != (self.dataSource?.sections())!)

        self.dataSource?.updateSections(["a","d","c"], animated: true)
        self.thenNumberOfSectionsIs(3)

        self.dataSource?.updateSections(["a","d","c","e"], animated: true)
        self.thenNumberOfSectionsIs(4)

        self.dataSource?.updateSections([], animated: true)
        self.thenNumberOfSectionsIs(0)

        var didFail = false
        self.dataSource?.fail = { (msg) -> Void in didFail = true }

        self.dataSource?.updateSections(["a","a","a"], animated: true)
        XCTAssert(didFail)
    }

    func testDataSourceRows() {
        self.givenDelegateAndDataSource()

        var didWarn = false
        self.dataSource?.warn = { (message: String?) -> Void in
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
        XCTAssert(self.mockTVItemsForIdentifiers(["0","1","2"]) == (self.dataSource?.rowsForSection("a"))!)

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","2","3"], sectionID: "a")
        self.thenNumberOfSectionsIs(3)
        self.thenInsertionRowsSectionsAre([[2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        var didFail = false
        self.dataSource?.fail = { (msg) -> Void in didFail = true }
        self.whenUpdatingRowsWithIdentifiers(["0","0","0"], sectionID: "a")
        XCTAssert(didFail)
    }

    func testDataSourceRowsDelete() {
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

    func testDataSourceWhenCompletelyEmpty() {
        self.givenDelegateAndDataSource()

        self.thenNumberOfSectionsIs(0)

        // note: asking for the number of rows in section 0 would result in a fail as we don't have a sectionID.
    }

    func testDidSelect() {
        self.givenDelegateAndDataSource()
        self.givenWillAllowSelectInSectionID("a", rowID: "1")

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.whenSelectingRow(1, section: 0)
        self.thenCanSelectHandlerWasCalled()
    }

    func testCanMove() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "2")

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.thenCanMoveItemAtRow(2, section: 0, canMove: true)
        self.thenCanMoveItemAtRow(1, section: 0, canMove: false)
    }

    func testMove() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "2")
        self.givenExpectRowIDsAfterMove(["0","2","1"], forSectionID: "a", withSectionCount: 1)


        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.whenMovingRow(2, sourceSection: 0, toRow: 1, toSection: 0)
    }

    func testMoveBeyondLastItem() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "1")
        self.givenExpectRowIDsAfterMove(["0","2","1"], forSectionID: "a", withSectionCount: 1)

        self.whenUpdatingSectionIDs(["a","b","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "a")
        self.thenNumberOfRowsIs(3, sectionIndex: 0)

        self.whenMovingRow(1, sourceSection: 0, toRow: 3, toSection: 0)
    }


    func testMoveAcrossSections() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "3")

        self.whenUpdatingSectionIDs(["a","b","c"])

        self.whenUpdatingRowsWithIdentifiers(["0","1","2","3"], sectionID: "a")
        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "b")

        let expectation = expectationWithDescription("sections changed callback")

        guard let dataSource = self.dataSource else {
            XCTFail()
            return
        }

        dataSource.didChangeSectionIDs = { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
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

        self.whenMovingRow(3, sourceSection: 0, toRow: 2, toSection: 1)

        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testMoveWithCorrectedTarget() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "3")
        self.givenRetargetsToRowIDSectionID("1", sectionID: "a")

        self.whenUpdatingSectionIDs(["a","b","c"])

        self.whenUpdatingRowsWithIdentifiers(["0","1","2","3"], sectionID: "a")
        self.whenUpdatingRowsWithIdentifiers(["0","1","2"], sectionID: "b")

        guard let dataSource = self.dataSource else {
            XCTFail()
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        let indexPath = dataSource.tableView(tableView, targetIndexPathForMoveFromRowAtIndexPath: NSIndexPath(forRow: 3, inSection: 0), toProposedIndexPath: NSIndexPath(forRow: 2, inSection: 0))
        XCTAssert(indexPath.section == 0)
        XCTAssert(indexPath.row == 1)
    }

    // testing: optional func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    func testCanEditItem() {
        self.givenDelegateAndDataSource()
        self.givenCanEditItemAtSectionID("a", rowID: "1")

        self.whenUpdatingSectionIDs(["a"])
        self.whenUpdatingRowsWithIdentifiers(["0","1","2","3"], sectionID: "a")

        self.thenCanEditItemAtRow(1, section: 0, canMove: true)
        self.thenCanEditItemAtRow(0, section: 0, canMove: false)
        self.thenCanEditItemAtRow(1000, section: 0, canMove: false)
        self.thenCanEditItemAtRow(0, section: 1000, canMove: false)
    }

    func testDeleteItem() {
        self.givenDelegateAndDataSource()
        self.whenUpdatingSectionIDs(["a"])
        self.whenUpdatingRowsWithIdentifiers(["0","1","2","3"], sectionID: "a")

        let willDeleteExpectation = expectationWithDescription("will delete callback")
        let didDeleteExpectation = expectationWithDescription("did delete callback")
        let sectionChangedExpectation = expectationWithDescription("sections changed callback")

        guard let dataSource = self.dataSource else {
            XCTFail()
            return
        }
        dataSource.willDelete = { (atLocation: Location<MockTVItem>) -> Void in
            XCTAssert(atLocation.sectionID == "a")
            XCTAssert(atLocation.item.identifier == "1")
            willDeleteExpectation.fulfill()
        }

        dataSource.didDelete = { (item: MockTVItem) -> Void in
            XCTAssert(item.identifier == "1")
            didDeleteExpectation.fulfill()
        }

        dataSource.didChangeSectionIDs = { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
            sectionChangedExpectation.fulfill()
            XCTAssert(inSectionIDs.count == 1, "should be only one section")

            guard let rows = inSectionIDs["a"] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == ["0","2","3"])

        }

        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        dataSource.tableView(tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete, forRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testHeaderAndFooterTitles() {
        self.givenDelegateAndDataSource()
        self.givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles()
        self.whenUpdatingSectionIDs(["a", "b"])

        self.thenSectionHeaderTitle(forSectionIndex: 0, isString: "a", footerIsString: "aa")
        self.thenSectionHeaderTitle(forSectionIndex: 1, isString: "b", footerIsString: "bb")
    }

}
