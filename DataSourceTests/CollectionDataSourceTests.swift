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


// test files can be longer, right?
// swiftlint:disable file_length


import XCTest

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
        let cell = dataSource.dequeueReusableCellWithReuseIdentifier("Cell", sectionID: sectionID, item: inItem)

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

        dataSource.setFailFunc(failFunc: failFunc)
    }

    override func setWarnFunc(warnFunc: (String) -> Void) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.setWarnFunc(warnFunc: warnFunc)
    }

    override func setDidChangeSectionIDsFunc(didChangeFunc: ((inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void)) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }

        dataSource.setDidChangeSectionIDsFunc(didChangeFunc: didChangeFunc)
    }

    // MARK: - given

    override func givenDelegateAndDataSource() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        self.collectionView = MockCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 960), collectionViewLayout: collectionViewLayout)
        self.collectionView?.registerClass(MockCollectionViewCell.classForKeyedUnarchiver(), forCellWithReuseIdentifier: "Cell")
        guard let collectionView = self.collectionView else {
            XCTFail("could not instantiate table view")
            return
        }
        self.dataSource = CollectionDataSource<MockTVItem>(collectionView: collectionView) { (inLocation: Location<MockTVItem>) -> UICollectionViewCell in
            self.cellForSectionID(inLocation.sectionID, item: inLocation.item, collectionView: collectionView)
        }
        self.dataSource?.setReportingLevel(.PreCondition)

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

    override func givenCanMoveItemAtSectionID(inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canMove = {(toLocation: Location<MockTVItem>) -> Bool in
            return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
        }
    }

    override func givenExpectRowIDsAfterMove(rowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.setDidChangeSectionIDsFunc(didChangeFunc: { (inSectionIDs: Dictionary<String, Array<MockTVItem>>) -> Void in
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
    // MARK: - when

    override func whenUpdating(sectionIDs: Array<String>) {
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
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        dataSource.collectionView(collectionView, didSelectItemAtIndexPath: indexPath)
    }

    override func whenMovingRow(sourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        dataSource.collectionView(collectionView, moveItemAtIndexPath: NSIndexPath(forRow: sourceRow, inSection: sourceSection), toIndexPath: NSIndexPath(forRow: destinationRow, inSection: destinationSection))
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
        XCTAssert(dataSource.numberOfSectionsInCollectionView(collectionView) == inNumberOfSections, "...")
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
        XCTAssert(dataSource.collectionView(collectionView, numberOfItemsInSection: sectionIndex) == numberOfRows)
    }

    override func thenInsertionRowsSectionsAre(indexPaths inIndexPaths: [[Int]]) {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = indexPaths.map(testHelper_indexListMapper())

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
        XCTAssert(dataSource.collectionView(collectionView, canMoveItemAtIndexPath: NSIndexPath(forRow: row, inSection: section)) == canMove)

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
