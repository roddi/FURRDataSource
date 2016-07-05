// swiftlint:disable line_length
// swiftlint:disable type_body_length
//
//  DBDBDataSourceTests.swift
//  DBDB
//
//  Created by Ruotger Deecke on 28.07.15.
//  Copyright © 2015 Deecke,Roddi. All rights reserved.
//
// swiftlint:disable file_length

import XCTest


class TableDataSourceTests: BaseDataSourceTests {

    var tableView: MockTableView? = nil
    var dataSource: TableDataSource<MockTVItem>? = nil
    var didCallDidSelectHandler = false

    // MARK: - helper

    override func sections() -> [String] {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return [] // <-- will fail anyway
        }

        return dataSource.sections()
    }

    override func rowsForSection(section: String) -> [MockTVItem] {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return [] // <-- will fail anyway
        }

        return dataSource.rowsForSection(section)
    }

    override func setFailFunc(failFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.setFailFunc(failFunc)
    }

    override func setWarnFunc(warnFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.setWarnFunc(warnFunc)
    }

    override func setDidChangeSectionIDsFunc(didChangeFunc: ((inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void)) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.setDidChangeSectionIDsFunc(didChangeFunc)
    }

    // MARK: - given

    override func givenDelegateAndDataSource() {
        self.tableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), style: .Plain)
        guard let tableView = self.tableView else {
            XCTFail("could not instantiate table view")
            return
        }
        self.dataSource = TableDataSource<MockTVItem>(tableView: tableView) { (inLocation: Location<MockTVItem>) -> UITableViewCell in
            cellForSectionID(inLocation.sectionID, item: inLocation.item, tableView: tableView)
        }
        self.dataSource?.setReportingLevel(.PreCondition)

        tableView.insertRowsCallback = { print("insert rows \($0)") }
        tableView.deleteRowsCallback = { print("delete rows \($0)") }
        tableView.insertSectionsCallback = { print("insert sections \($0)") }
        tableView.deleteSectionsCallback = { print("delete sections \($0)") }
        didCallDidSelectHandler = false
    }

    override func givenCanMoveItemAtSectionID(inSectionID: String, rowID inRowID: String) {
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

    override func givenWillAllowSelectInSectionID(sectionID: String, rowID inRowID: String) {
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

    override func givenDiffsAreCleared() {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        tableView.deletionRowIndexPaths = []
        tableView.insertionRowIndexPaths = []
        tableView.insertionSectionIndexSet = NSMutableIndexSet()
        tableView.deletionSectionIndexSet = NSMutableIndexSet()
    }

    override func givenExpectRowIDsAfterMove(rowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setDidChangeSectionIDsFunc({ (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
            XCTAssert(inSectionIDs.count == sectionCount)

            guard let rows = inSectionIDs[sectionID] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == rowIDs)
        })

    }

    func givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles() {
        self.dataSource?.sectionHeaderTitle = { return $0 }
        self.dataSource?.sectionFooterTitle = { return $0+$0 }
    }

    // MARK: - when

    override func whenUpdatingSectionIDs(inSectionIDs: Array<String>) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.updateSections(inSectionIDs, animated: true)
    }

    override func whenUpdatingRowsWithIdentifiers(identifiers: [String], sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.updateRows(MockTVItem.mockTVItems(identifiers: identifiers), section: sectionID, animated: true)
    }

    override func whenSelectingRow(row: Int, section: Int) {
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

    override func whenMovingRow(sourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
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

    override func thenNumberOfSectionsIs(numberOfSections inNumberOfSections: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == inNumberOfSections, "...")
    }

    override func thenNumberOfRowsIs(numberOfRows inNumberOfRows: Int, sectionIndex: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        XCTAssert(dataSource.tableView(tableView, numberOfRowsInSection: sectionIndex) == inNumberOfRows)
    }

    override func thenInsertionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssert(tableView.insertionRowIndexPaths == realIndexPaths)
    }

    override func thenDeletionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssert(tableView.deletionRowIndexPaths == realIndexPaths)
    }

    override func thenCanSelectHandlerWasCalled() {
        XCTAssert(self.didCallDidSelectHandler)
    }

    override func thenCanMoveItem(atRow row: Int, section: Int, canMove: Bool) {
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
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: indexPath) == canMove)
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

    // MARK: - test

    func testDataSourceSections() {
        self.baseTestDataSourceSections()
    }

    func testDataSourceRows() {
        self.baseTestDataSourceRows()
    }

    func testDataSourceRowsDelete() {
        self.baseTestDataSourceRowsDelete()
    }

    func testDataSourceWhenCompletelyEmpty() {
        self.baseTestDataSourceWhenCompletelyEmpty()
    }

    func testDidSelect() {
        self.baseTestDidSelect()
    }

    func testCanMove() {
        self.baseTestCanMove()
    }

    func testMove() {
        self.baseTestMove()
    }

    func testMoveBeyondLastItem() {
        self.baseTestMoveBeyondLastItem()
    }

    func testMoveAcrossSections() {
        self.baseTestMoveAcrossSections()
    }

    func testMoveWithCorrectedTarget() {
        self.givenDelegateAndDataSource()
        self.givenCanMoveItemAtSectionID("a", rowID: "3")
        self.givenRetargetsToRowIDSectionID("1", sectionID: "a")

        self.whenUpdatingSectionIDs(["a", "b", "c"])

        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2", "3"], sectionID: "a")
        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2"], sectionID: "b")

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
        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2", "3"], sectionID: "a")

        self.thenCanEditItemAtRow(1, section: 0, canMove: true)
        self.thenCanEditItemAtRow(0, section: 0, canMove: false)
        self.thenCanEditItemAtRow(1000, section: 0, canMove: false)
        self.thenCanEditItemAtRow(0, section: 1000, canMove: false)
    }

    func testDeleteItem() {
        self.givenDelegateAndDataSource()
        self.whenUpdatingSectionIDs(["a"])
        self.whenUpdatingRowsWithIdentifiers(["0", "1", "2", "3"], sectionID: "a")

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

        dataSource.setDidChangeSectionIDsFunc({ (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
            sectionChangedExpectation.fulfill()
            XCTAssert(inSectionIDs.count == 1, "should be only one section")

            guard let rows = inSectionIDs["a"] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == ["0", "2", "3"])

        })

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
