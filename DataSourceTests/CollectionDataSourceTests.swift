// swiftlint:disable line_length
//
//  CollectionDataSourceTests.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 14.01.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
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


// I hope you don't mind that test files are longer.
// swiftlint:disable file_length
// swiftlint:disable type_body_length

import XCTest
@testable import FURRDataSource

class CollectionDataSourceTests: BaseDataSourceTests {

    var collectionView: MockCollectionView? = nil
    var dataSource: CollectionDataSource<MockTVItem>? = nil
    var didCallDidSelectHandler = false

    // MARK: - helper

    func cellForSectionID(sectionID: String, item inItem: MockTVItem, collectionView inCollectionView: UICollectionView) -> UICollectionViewCell {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return UICollectionViewCell() // <-- will fail anyway
        }
        #if swift(>=3.0)
            let cell = dataSource.dequeueReusableCell(withReuseIdentifier: "Cell", sectionID: sectionID, item: inItem)
        #else
            let cell = dataSource.dequeueReusableCellWithReuseIdentifier("Cell", sectionID: sectionID, item: inItem)
        #endif

        if let cell_ = cell {
            return cell_
        } else {
            return UICollectionViewCell() // <-- will fail anyway
        }
    }

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

    #if swift(>=3.0)
    override func setFunc(warn warnFunc: @escaping (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFunc(warn: warnFunc)
    }

    override func setFunc(fail failFunc: @escaping (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFunc(fail: failFunc)
    }

    override func setDidChangeSectionIDsFunc(didChangeFunc inDidChangeFunc: @escaping ((Dictionary<String, Array<MockTVItem>>) -> Void)) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFunc(didChangeSectionIDsFunc: inDidChangeFunc)
    }

    #else
    override func setFunc(warn warnFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setWarnFunc(warnFunc)
    }

    override func setFunc(fail inFailFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setFailFunc(inFailFunc)
    }

    override func setDidChangeSectionIDsFunc(didChangeFunc inDidChangeFunc: ((Dictionary<String, Array<MockTVItem>>) -> Void)) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setDidChangeSectionIDsFunc(inDidChangeFunc)
    }

    #endif

    // MARK: - given

    override func givenDelegateAndDataSource() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView = MockCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), collectionViewLayout: collectionViewLayout)
        #if swift(>=3.0)
            self.collectionView?.register(MockCollectionViewCell.classForKeyedUnarchiver(), forCellWithReuseIdentifier: "Cell")
        #else
            self.collectionView?.registerClass(MockCollectionViewCell.classForKeyedUnarchiver(), forCellWithReuseIdentifier: "Cell")
        #endif
        guard let collectionView = self.collectionView else {
            XCTFail("could not instantiate table view")
            return
        }
        self.dataSource = CollectionDataSource<MockTVItem>(collectionView: collectionView) { (inLocation: Location<MockTVItem>) -> UICollectionViewCell in
            #if swift(>=3.0)
                return self.cellForSectionID(sectionID: inLocation.sectionID, item: inLocation.item, collectionView: collectionView)
            #else
                return self.cellForSectionID(inLocation.sectionID, item: inLocation.item, collectionView: collectionView)
            #endif
        }
        #if swift(>=3.0)
            self.dataSource?.setReporting(level: .preCondition)
        #else
            self.dataSource?.setReportingLevel(.PreCondition)
        #endif

        collectionView.insertRowsCallback = { print("insert rows \($0)") }
        collectionView.deleteRowsCallback = { print("delete rows \($0)") }
        collectionView.insertSectionsCallback = { print("insert sections \($0)") }
        collectionView.deleteSectionsCallback = { print("delete sections \($0)") }
        didCallDidSelectHandler = false
    }

    override func givenDiffsAreCleared() {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        collectionView.deletionRowIndexPaths = []
        collectionView.insertionRowIndexPaths = []
        collectionView.insertionSectionIndexSet = NSMutableIndexSet()
        collectionView.deletionSectionIndexSet = NSMutableIndexSet()
    }

    override func givenWillAllowSelect(sectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        didCallDidSelectHandler = false
        #if swift(>=3.0)
            dataSource.didSelectLocation = { (inLocation: Location<MockTVItem>) -> Void in
                XCTAssert(inLocation.sectionID == "a")
                XCTAssert(inLocation.item.identifier == "1")
                self.didCallDidSelectHandler = true
            }
        #else
            dataSource.didSelect = { (inLocation: Location<MockTVItem>) -> Void in
                XCTAssert(inLocation.sectionID == "a")
                XCTAssert(inLocation.item.identifier == "1")
                self.didCallDidSelectHandler = true
            }
        #endif
    }

    override func givenCanMoveItem(atSectionID inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        #if swift(>=3.0)
            dataSource.canMoveToLocation = {(toLocation: Location<MockTVItem>) -> Bool in
                return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
            }
        #else
            dataSource.canMove = {(toLocation: Location<MockTVItem>) -> Bool in
                return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
            }
        #endif
    }

    override func givenExpectRowIDsAfterMove(rowIDs inRowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        let didChangeSectionIDsFunc = { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
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
            dataSource.setFunc(didChangeSectionIDsFunc: didChangeSectionIDsFunc)
        #else
            dataSource.setDidChangeSectionIDsFunc(didChangeSectionIDsFunc)
        #endif
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

    override func whenUpdating(rowsWithIdentifiers inRows: [String], sectionID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        #if swift(>=3.0)
            dataSource.update(rows: MockTVItem.mockTVItems(identifiers: inRows), section: sectionID, animated: true)
        #else
            dataSource.updateRows(MockTVItem.mockTVItems(identifiers: inRows), section: sectionID, animated: true)
        #endif
    }

    override func whenSelecting(row inRow: Int, section: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            let indexPath = IndexPath(row: inRow, section: section)
            dataSource.collectionView(collectionView, didSelectItemAt: indexPath)
        #else
            let indexPath = NSIndexPath(forRow: inRow, inSection: section)
            dataSource.collectionView(collectionView, didSelectItemAtIndexPath: indexPath)
        #endif
    }

    override func whenMoving(sourceRow inSourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            dataSource.collectionView(collectionView, moveItemAt: IndexPath(row: inSourceRow, section: sourceSection), to: IndexPath(row: destinationRow, section: destinationSection))
        #else
            dataSource.collectionView(collectionView, moveItemAtIndexPath: NSIndexPath(forRow: inSourceRow, inSection: sourceSection), toIndexPath: NSIndexPath(forRow: destinationRow, inSection: destinationSection))
        #endif
    }
    // MARK: - then

    override func thenNumberOfSectionsIs(numberOfSections inNumberOfSections: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no collection view")
            return
        }
        #if swift(>=3.0)
            XCTAssert(dataSource.numberOfSections(in: collectionView) == inNumberOfSections, "...")
        #else
            XCTAssert(dataSource.numberOfSectionsInCollectionView(collectionView) == inNumberOfSections, "...")
        #endif
    }

    // should be called thenNumberOfItemsIs(...). Any volunteers for a pull request?
    override func thenNumberOfRowsIs(numberOfRows inNumberOfRows: Int, sectionIndex: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no collection view")
            return
        }
        XCTAssert(dataSource.collectionView(collectionView, numberOfItemsInSection: sectionIndex) == inNumberOfRows)
    }

    override func thenInsertionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssert(collectionView.insertionRowIndexPaths == realIndexPaths)
    }

    override func thenDeletionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = inIndexPaths.map(testHelper_indexListMapper())

        XCTAssert(collectionView.deletionRowIndexPaths == realIndexPaths)
    }

    override func thenCanSelectHandlerWasCalled() {
        XCTAssert(self.didCallDidSelectHandler)
    }

    override func thenCanMoveItem(atRow row: Int, section: Int, canMove: Bool) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        #if swift(>=3.0)
            XCTAssert(dataSource.collectionView(collectionView, canMoveItemAt: IndexPath(row: row, section: section)) == canMove)
        #else
            XCTAssert(dataSource.collectionView(collectionView, canMoveItemAtIndexPath: NSIndexPath(forRow: row, inSection: section)) == canMove)
        #endif

    }

    // MARK: - override test

    // This test crashes from time to time but only for the collection view.
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

}
