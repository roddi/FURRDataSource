//
//  DBDBDataSourceTests.swift
//  DBDB
//
//  Created by Ruotger Deecke on 28.07.15.
//  Copyright © 2015 Deecke,Roddi. All rights reserved.
//
// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

import XCTest
@testable import FURRDataSource

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

    override func rows(forSection: String) -> [MockTVItem] {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return [] // <-- will fail anyway
        }

        #if swift(>=3.0)
            return dataSource.rows(forSection: forSection)
        #else
            return dataSource.rowsForSection(forSection)
        #endif
    }

    override func setFunc(fail inFailFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        #if swift(>=3.0)
            dataSource.setFunc(fail: inFailFunc)
            #else
            dataSource.setFailFunc(inFailFunc)
            #endif
    }

    override func setFunc(warn inWarnFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        #if swift(>=3.0)
            dataSource.setFunc(warn: inWarnFunc)
        #else
            dataSource.setWarnFunc(inWarnFunc)
        #endif
    }

    override func setDidChangeSectionIDsFunc(didChangeFunc inDidChangeFunc: ((inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void)) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        #if swift(>=3.0)
            dataSource.setDidChangeSectionIDsFunc(didChangeFunc: inDidChangeFunc)
        #else
            dataSource.setDidChangeSectionIDsFunc(inDidChangeFunc)
        #endif
    }

    // MARK: - given

    override func givenDelegateAndDataSource() {
        self.tableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), style: CompatUITableViewStyle.plain.uiStyle())
        guard let tableView = self.tableView else {
            XCTFail("could not instantiate table view")
            return
        }
        self.dataSource = TableDataSource<MockTVItem>(tableView: tableView) { (inLocation: Location<MockTVItem>) -> UITableViewCell in
            #if swift(>=3.0)
                return cellForSectionID(inSectionID: inLocation.sectionID, item: inLocation.item, tableView: tableView)
            #else
                return cellForSectionID(inLocation.sectionID, item: inLocation.item, tableView: tableView)
            #endif
        }
        #if swift(>=3.0)
            self.dataSource?.setReporting(level: .preCondition)
        #else
            self.dataSource?.setReportingLevel(.PreCondition)
        #endif

        tableView.insertRowsCallback = { print("insert rows \($0)") }
        tableView.deleteRowsCallback = { print("delete rows \($0)") }
        tableView.insertSectionsCallback = { print("insert sections \($0)") }
        tableView.deleteSectionsCallback = { print("delete sections \($0)") }
        didCallDidSelectHandler = false
    }

    override func givenCanMoveItem(atSectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canMove = {(toLocation: Location<MockTVItem>) -> Bool in
            return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
        }
    }

    func givenRetargetsTo(rowID inRowID: String, sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        let location = LocationWithOptionalItem(sectionID: sectionID, item: MockTVItem(identifier: inRowID))
        dataSource.targetMovedItem = { (fromLocation: Location<MockTVItem>, proposedLocation: LocationWithOptionalItem<MockTVItem>) -> LocationWithOptionalItem<MockTVItem> in
            return location
        }
    }

    func givenCanEditItemAt(sectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canEdit = {(atLocation: Location<MockTVItem>) -> Bool in
            return atLocation.sectionID == inSectionID && atLocation.item.identifier == inRowID
        }
    }

    override func givenWillAllowSelect(sectionID inSectionID: String, rowID inRowID: String) {
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

    override func givenExpectRowIDsAfterMove(rowIDs inRowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        let didChangeFunc = { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
            XCTAssert(inSectionIDs.count == sectionCount)

            guard let rows = inSectionIDs[sectionID] else {
                XCTFail("no rows?")
                return
            }

            let mappedIDs = rows.map({ (item) -> String in
                return item.identifier
            })

            XCTAssert(mappedIDs == inRowIDs)
        }
        #if swift(>=3.0)
            dataSource.setDidChangeSectionIDsFunc(didChangeFunc: didChangeFunc)
        #else
            dataSource.setDidChangeSectionIDsFunc(didChangeFunc)
        #endif

    }

    func givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles() {
        self.dataSource?.sectionHeaderTitle = { return $0 }
        self.dataSource?.sectionFooterTitle = { return $0+$0 }
    }

    // MARK: - when

    override func whenUpdating(sectionIDs inSectionIDs: Array<String>) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        #if swift(>=3.0)
            dataSource.update(sections: inSectionIDs, animated: true)
        #else
            dataSource.updateSections(inSectionIDs, animated: true)
        #endif
    }

    override func whenUpdating(rowsWithIdentifiers inRowIDs: [String], sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        #if swift(>=3.0)
            dataSource.update(rows: MockTVItem.mockTVItems(identifiers: inRowIDs), section: sectionID, animated: true)
        #else
            dataSource.updateRows(MockTVItem.mockTVItems(identifiers: inRowIDs), section: sectionID, animated: true)
        #endif
    }

    override func whenSelecting(row inRow: Int, section: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            let indexPath = IndexPath(row: inRow, section: section)
            dataSource.tableView(tableView, didSelectRowAt: indexPath)
        #else
            let indexPath = NSIndexPath(forRow: inRow, inSection: section)
            dataSource.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        #endif

    }

    override func whenMoving(sourceRow inSourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            dataSource.tableView(tableView, moveRowAt: IndexPath(row: inSourceRow, section: sourceSection), to: IndexPath(row: destinationRow, section: destinationSection))
        #else
            dataSource.tableView(tableView, moveRowAtIndexPath: NSIndexPath(forRow: inSourceRow, inSection: sourceSection), toIndexPath: NSIndexPath(forRow: destinationRow, inSection: destinationSection))
        #endif
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
        #if swift(>=3.0)
            XCTAssert(dataSource.numberOfSections(in: tableView) == inNumberOfSections, "...")
        #else
            XCTAssert(dataSource.numberOfSectionsInTableView(tableView) == inNumberOfSections, "...")
        #endif
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
        #if swift(>=3.0)
            XCTAssert(dataSource.tableView(tableView, canMoveRowAt: IndexPath(row: row, section: section)) == canMove)
        #else
            XCTAssert(dataSource.tableView(tableView, canMoveRowAtIndexPath: NSIndexPath(forRow: row, inSection: section)) == canMove)
        #endif

    }

    func thenCanEditItem(atRow inRow: Int, section: Int, canMove: Bool) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            let indexPath = IndexPath(row: inRow, section: section)
            XCTAssert(dataSource.tableView(tableView, canEditRowAt: indexPath) == canMove)
        #else
            let indexPath = NSIndexPath(forRow: inRow, inSection: section)
            XCTAssert(dataSource.tableView(tableView, canEditRowAtIndexPath: indexPath) == canMove)
        #endif
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
        self.givenCanMoveItem(atSectionID: "a", rowID: "3")
        self.givenRetargetsTo(rowID: "1", sectionID: "a")

        self.whenUpdatingSectionIDs(["a", "b", "c"])

        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2", "3"], sectionID: "a")
        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2"], sectionID: "b")

        guard let dataSource = self.dataSource else {
            XCTFail()
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            let indexPath = dataSource.tableView(tableView, targetIndexPathForMoveFromRowAt: IndexPath(row: 3, section: 0), toProposedIndexPath: IndexPath(row: 2, section: 0))
        #else
            let indexPath = dataSource.tableView(tableView, targetIndexPathForMoveFromRowAtIndexPath: NSIndexPath(forRow: 3, inSection: 0), toProposedIndexPath: NSIndexPath(forRow: 2, inSection: 0))
        #endif
        XCTAssert(indexPath.section == 0)
        XCTAssert(indexPath.row == 1)
    }

    // testing: optional func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    func testCanEditItem() {
        self.givenDelegateAndDataSource()
        self.givenCanEditItemAt(sectionID: "a", rowID: "1")

        self.whenUpdatingSectionIDs(["a"])
        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2", "3"], sectionID: "a")

        self.thenCanEditItem(atRow: 1, section: 0, canMove: true)
        self.thenCanEditItem(atRow: 0, section: 0, canMove: false)
        self.thenCanEditItem(atRow: 1000, section: 0, canMove: false)
        self.thenCanEditItem(atRow: 0, section: 1000, canMove: false)
    }

    func testDeleteItem() {
        self.givenDelegateAndDataSource()
        self.whenUpdatingSectionIDs(["a"])
        self.whenUpdating(rowsWithIdentifiers: ["0", "1", "2", "3"], sectionID: "a")

        #if swift(>=3.0)
            let willDeleteExpectation = expectation(description: "will delete callback")
            let didDeleteExpectation = expectation(description: "did delete callback")
            let sectionChangedExpectation = expectation(description: "sections changed callback")
        #else
            let willDeleteExpectation = expectationWithDescription("will delete callback")
            let didDeleteExpectation = expectationWithDescription("did delete callback")
            let sectionChangedExpectation = expectationWithDescription("sections changed callback")
        #endif

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

        let didChangeFunc = { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
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
        }

        #if swift(>=3.0)
            dataSource.setDidChangeSectionIDsFunc(didChangeFunc: didChangeFunc)
            #else
            dataSource.setDidChangeSectionIDsFunc(didChangeFunc)
            #endif

        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            dataSource.tableView(tableView, commit: UITableViewCellEditingStyle.delete, forRowAt: IndexPath(row: 1, section: 0))
            waitForExpectations(timeout: 10, handler: nil)
        #else
            dataSource.tableView(tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete, forRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
            waitForExpectationsWithTimeout(10, handler: nil)
        #endif
    }

    func testHeaderAndFooterTitles() {
        self.givenDelegateAndDataSource()
        self.givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles()
        self.whenUpdatingSectionIDs(["a", "b"])

        self.thenSectionHeaderTitle(forSectionIndex: 0, isString: "a", footerIsString: "aa")
        self.thenSectionHeaderTitle(forSectionIndex: 1, isString: "b", footerIsString: "bb")
    }

}
