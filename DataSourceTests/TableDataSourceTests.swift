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

import XCTest
@testable import FURRDataSource

class TableDataSourceTests: BaseDataSourceTests {

    var tableView: MockTableView?
    var dataSource: TableDataSource<MockTVItem>?
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

        return dataSource.rows(forSection: forSection)
    }

    override func setFunc(fail inFailFunc: @escaping (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFunc(fail: inFailFunc)
    }

    override func setFunc(warn inWarnFunc: @escaping (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFunc(warn: inWarnFunc)
    }

    override func setDidChangeSectionIDsFunc(didChangeFunc inDidChangeFunc: @escaping(([String: [MockTVItem]]) -> Void)) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFunc(didChangeSectionIDsFunc: inDidChangeFunc)
    }

    // MARK: - given

    override func givenDelegateAndDataSource() {
        self.tableView = MockTableView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), style: UITableView.Style.plain)
        guard let tableView = self.tableView else {
            XCTFail("could not instantiate table view")
            return
        }
        self.dataSource = TableDataSource<MockTVItem>(tableView: tableView) { (inLocation: Location<MockTVItem>) -> UITableViewCell in
            return cellForSectionID(inSectionID: inLocation.sectionID, item: inLocation.item, tableView: tableView)
        }
        self.dataSource?.setReporting(level: .preCondition)

        tableView.insertRowsCallback = { print("insert rows \($0)") }
        tableView.deleteRowsCallback = { print("delete rows \($0)") }
        tableView.reloadRowsCallback = { print("reload rows \($0)") }
        tableView.insertSectionsCallback = { print("insert sections \($0)") }
        tableView.deleteSectionsCallback = { print("delete sections \($0)") }
        tableView.dequeuedCellCallback = { (text: String?, detailText: String?) in
            print("text: \(text ?? "nil") -- detailText: \(detailText ?? "nil")")}
        didCallDidSelectHandler = false
    }

    override func givenCanMoveItem(atSectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canMoveToLocation = {(toLocation: Location<MockTVItem>) -> Bool in
            return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
        }
    }

    func givenRetargetsTo(rowID inRowID: String, sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        let location = LocationWithOptionalItem(sectionID: sectionID, item: MockTVItem(identifier: inRowID))
        dataSource.targetMovedItemFromLocationToProposedLocation = { (fromLocation: Location<MockTVItem>, proposedLocation: LocationWithOptionalItem<MockTVItem>) -> LocationWithOptionalItem<MockTVItem> in
            return location
        }
    }

    func givenCanEditItemAt(sectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.canEditAtLocation = {(atLocation: Location<MockTVItem>) -> Bool in
            return atLocation.sectionID == inSectionID && atLocation.item.identifier == inRowID
        }
    }

    override func givenWillAllowSelect(sectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        didCallDidSelectHandler = false
        dataSource.didSelectLocation = { (inLocation: Location<MockTVItem>) -> Void in
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
        tableView.reloadRowIndexPaths = []
        tableView.insertionSectionIndexSet = NSMutableIndexSet()
        tableView.deletionSectionIndexSet = NSMutableIndexSet()
    }

    override func givenExpectRowIDsAfterMove(rowIDs inRowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        let didChangeFunc = { (inSectionIDs: [String: [MockTVItem]]) -> Void in
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
        dataSource.setFunc(didChangeSectionIDsFunc: didChangeFunc)

    }

    func givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles() {
        self.dataSource?.sectionHeaderTitleForSectionID = { return $0 }
        self.dataSource?.sectionFooterTitleForSectionID = { return $0+$0 }
    }

    // MARK: - when

    override func whenUpdating(sectionIDs inSectionIDs: [String]) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.update(sections: inSectionIDs, animated: true)
    }

    override func whenUpdating(rowsWithIdentifiers inRowIDs: [String], sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.update(rows: MockTVItem.mockTVItems(identifiers: inRowIDs), section: sectionID, animated: true)
    }

    override func whenUpdating(rowsWithTupels inRows: [(String, String?)], sectionID: String, file: StaticString = #file, line: UInt = #line) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source", file: file, line: line)
            return
        }

        dataSource.update(rows: MockTVItem.mockTVItems(identifiersAndAdditionalStrings: inRows), section: sectionID, animated: true)
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
        let indexPath = IndexPath(row: inRow, section: section)
        dataSource.tableView(tableView, didSelectRowAt: indexPath)
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
        dataSource.tableView(tableView, moveRowAt: IndexPath(row: inSourceRow, section: sourceSection), to: IndexPath(row: destinationRow, section: destinationSection))
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
        XCTAssert(dataSource.numberOfSections(in: tableView) == inNumberOfSections, "...")
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

    override func thenInsertionRowsSectionsAre(indexPaths inIndexPaths: [[Int]], file: StaticString = #file, line: UInt = #line) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssertEqual(tableView.insertionRowIndexPaths, realIndexPaths, file: file, line: line)
    }

    override func thenDeletionRowsSectionsAre(indexPaths inIndexPaths: [[Int]], file: StaticString = #file, line: UInt = #line) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssertEqual(tableView.deletionRowIndexPaths, realIndexPaths, file: file, line: line)
    }

    override func thenReloadRowsSectionsAre(indexPaths inIndexPaths: [[Int]], file: StaticString = #file, line: UInt = #line) {
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssertEqual(tableView.reloadRowIndexPaths, realIndexPaths, file: file, line: line)
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
        XCTAssert(dataSource.tableView(tableView, canMoveRowAt: IndexPath(row: row, section: section)) == canMove)

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
        let indexPath = IndexPath(row: inRow, section: section)
        XCTAssert(dataSource.tableView(tableView, canEditRowAt: indexPath) == canMove)
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

    override func thenAddtionalString(forIndexPath: IndexPath, isActually: String?, file: StaticString = #file, line: UInt = #line) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        let sectionIDAndItem = dataSource.sectionIDAndItem(indexPath: forIndexPath)
        XCTAssertEqual(sectionIDAndItem?.1.additionalString, isActually, file: file, line: line)
    }

    // MARK: - test

    func testDataSourceSections() {
        self.baseTestDataSourceSections()
    }

    func testDataSourceRows() {
        self.baseTestDataSourceRows()
    }

    func testDataSourceRowsAreCopied() {
        self.baseTestDataSourceRowsAreCopied()
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
            XCTFail("there must be a data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        let indexPath = dataSource.tableView(tableView, targetIndexPathForMoveFromRowAt: IndexPath(row: 3, section: 0), toProposedIndexPath: IndexPath(row: 2, section: 0))
        XCTAssert(indexPath.section == 0)
        XCTAssert(indexPath.row == 1)
    }

    func testUpdateWithoutIDChange() {

        self.givenDelegateAndDataSource()

        guard let dataSource = self.dataSource else {
            XCTFail("there must be a data source")
            return
        }
        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }

        let window = UIWindow(frame: tableView.bounds)
        window.screen = UIScreen.main
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(tableView)

        dataSource.setFunc(didChangeSectionIDsFunc: { (sectionIDsDict: [String: [MockTVItem]]) in
            sectionIDsDict.keys.forEach({ (sectionID: String) in
                print("will reload section with ID: \(sectionID)")
                dataSource.reload(sectionID: sectionID)
            })
        })

        self.whenUpdatingSectionIDs(["a", "b", "c"])

        tableView.dequeuedCellCallback = { (text: String?, detailText: String?) in
            print("text: \(text ?? "nil") - detailText: \(detailText ?? "nil")")
        }

        self.whenUpdating(rowsWithTupels: [("x", "A"), ("y", "A"), ("z", "A")], sectionID: "a")
        self.thenInsertionRowsSectionsAre(indexPaths: [[0, 0], [1, 0], [2, 0]])
        self.thenDeletionRowsSectionsAre(indexPaths: [])
        self.thenReloadRowsSectionsAre(indexPaths: [])

        self.givenDiffsAreCleared()

        self.whenUpdating(rowsWithTupels: [("x", "B"), ("y", "B"), ("z", "B")], sectionID: "a")
        self.thenInsertionRowsSectionsAre(indexPaths: [])
        self.thenDeletionRowsSectionsAre(indexPaths: [])
        self.thenReloadRowsSectionsAre(indexPaths: [[0, 0], [1, 0], [2, 0]])

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

        let willDeleteExpectation = expectation(description: "will delete callback")
        let didDeleteExpectation = expectation(description: "did delete callback")
        let sectionChangedExpectation = expectation(description: "sections changed callback")

        guard let dataSource = self.dataSource else {
            XCTFail("there must be a data source")
            return
        }
        dataSource.willDeleteAtLocation = { (atLocation: Location<MockTVItem>) -> Void in
            XCTAssert(atLocation.sectionID == "a")
            XCTAssert(atLocation.item.identifier == "1")
            willDeleteExpectation.fulfill()
        }

        dataSource.didDeleteItem = { (item: MockTVItem) -> Void in
            XCTAssert(item.identifier == "1")
            didDeleteExpectation.fulfill()
        }

        let didChangeFunc = { (inSectionIDs: [String: [MockTVItem]]) -> Void in
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

        dataSource.setFunc(didChangeSectionIDsFunc: didChangeFunc)

        guard let tableView = self.tableView else {
            XCTFail("no table view")
            return
        }
        dataSource.tableView(tableView, commit: UITableViewCell.EditingStyle.delete, forRowAt: IndexPath(row: 1, section: 0))
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testHeaderAndFooterTitles() {
        self.givenDelegateAndDataSource()
        self.givenTableViewReflectsSectionIDsAsHeaderAndFooterTitles()
        self.whenUpdatingSectionIDs(["a", "b"])

        self.thenSectionHeaderTitle(forSectionIndex: 0, isString: "a", footerIsString: "aa")
        self.thenSectionHeaderTitle(forSectionIndex: 1, isString: "b", footerIsString: "bb")
    }

}
