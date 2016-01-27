//
//  CollectionDataSourceTests.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 14.01.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import XCTest

class CollectionDataSourceTests: XCTestCase {

    var collectionView: MockCollectionView? = nil
    var dataSource: CollectionDataSource<MockTVItem>? = nil
    var didCallDidSelectHandler = false

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - helper

    func cellForSectionID(sectionID: String, item inItem: MockTVItem, collectionView inCollectionView: UICollectionView) -> UICollectionViewCell {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return UICollectionViewCell() // <-- will fail anyway
        }
        let cell = dataSource.dequeueReusableCellWithReuseIdentifier("Cell", sectionID: sectionID, item: inItem)

//        cell.textLabel?.text = inSectionID
//        cell.detailTextLabel?.text = rowID
        if let cell_ = cell {
            return cell_
        } else {
            return UICollectionViewCell() // <-- will fail anyway
        }
    }

    // MARK: - given

    func givenDelegateAndDataSource() {
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

    func givenDiffsAreCleared() {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }
        collectionView.deletionRowIndexPaths = []
        collectionView.insertionRowIndexPaths = []
        collectionView.insertionSectionIndexSet = NSMutableIndexSet()
        collectionView.deletionSectionIndexSet = NSMutableIndexSet()
    }

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

    func givenCanMoveItemAtSectionID(inSectionID: String, rowID inRowID: String) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        dataSource.canMove = {(toLocation: Location<MockTVItem>) -> Bool in
            return toLocation.sectionID == inSectionID && toLocation.item.identifier == inRowID
        }
    }

    func givenExpectRowIDsAfterMove(rowIDs: [String], forSectionID sectionID: String, withSectionCount sectionCount: Int) {
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

        dataSource.updateRows(MockTVItem.mockTVItemsForIdentifiers(identifiers), section: sectionID, animated: true)
    }

    func whenSelectingRow(row: Int, section: Int) {
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

    func whenMovingRow(sourceRow: Int, sourceSection: Int, toRow destinationRow: Int, toSection destinationSection: Int) {
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

    func thenNumberOfSectionsIs(numberOfSections: Int) {
        guard let dataSource = self.dataSource else {
            XCTFail("no data source")
            return
        }
        guard let collectionView = self.collectionView else {
            XCTFail("no collection view")
            return
        }
        XCTAssert(dataSource.numberOfSectionsInCollectionView(collectionView) == numberOfSections, "...")
    }

    // should be called thenNumberOfItemsIs(...). Any volunteers for a pull request?
    func thenNumberOfRowsIs(numberOfRows: Int, sectionIndex: Int) {
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

    func thenInsertionRowsSectionsAre(indexPaths: [[Int]]) {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = indexPaths.map(testHelper_indexListMapper())

        XCTAssert(collectionView.insertionRowIndexPaths == realIndexPaths)
    }

    func thenDeletionRowsSectionsAre(indexPaths: [[Int]]) {
        guard let collectionView = self.collectionView else {
            XCTFail("no table view")
            return
        }

        let realIndexPaths = indexPaths.map(testHelper_indexListMapper())

        XCTAssert(collectionView.deletionRowIndexPaths == realIndexPaths)
    }

    func thenCanSelectHandlerWasCalled() {
        XCTAssert(self.didCallDidSelectHandler)
    }

    func thenCanMoveItemAtRow(row: Int, section: Int, canMove: Bool) {
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

    // MARK: - test
    func testDataSourceSections() {
        self.givenDelegateAndDataSource()

        var sections = ["a","b","c"]
        self.whenUpdatingSectionIDs(sections)
        self.thenNumberOfSectionsIs(3)
        XCTAssert(["a","b","c"] == (self.dataSource?.sections())!)

        // test whether the data source hands out copies
        sections = ["a","b","c","d"]
        XCTAssert(sections != (self.dataSource?.sections())!)

        self.whenUpdatingSectionIDs(["a","d","c"])
        self.thenNumberOfSectionsIs(3)

        self.whenUpdatingSectionIDs(["a","d","c","e"])
        self.thenNumberOfSectionsIs(4)

        self.whenUpdatingSectionIDs([])
        self.thenNumberOfSectionsIs(0)

        var didFail = false
        self.dataSource?.setFailFunc({ (msg) -> Void in didFail = true })

        self.whenUpdatingSectionIDs(["a","a","a"])
        XCTAssert(didFail)
    }

    func testDataSourceRows() {
        self.givenDelegateAndDataSource()

        var didWarn = false
        self.dataSource?.setWarnFunc({ (message: String?) -> Void in
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
        XCTAssert(MockTVItem.mockTVItemsForIdentifiers(["0","1","2"]) == (self.dataSource?.rowsForSection("a"))!)

        self.givenDiffsAreCleared()

        self.whenUpdatingRowsWithIdentifiers(["0","2","3"], sectionID: "a")
        self.thenNumberOfSectionsIs(3)
        self.thenInsertionRowsSectionsAre([[2, 0]])
        self.thenDeletionRowsSectionsAre([[1, 0]])

        var didFail = false
        self.dataSource?.setFailFunc({ (msg) -> Void in didFail = true })
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

}
