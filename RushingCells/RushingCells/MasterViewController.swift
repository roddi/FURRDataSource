//
//  MasterViewController.swift
//  RushingCells
//
//  Created by Deecke,Roddi on 26.08.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

// This is sample code, so I disable all of this.

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable function_body_length

import UIKit

enum Breathing: String {
    case Inhale, Exhale, Keep
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    @IBOutlet weak var masterTableView: UITableView?
    var dataSource:DataSource<Rusher>? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            // swiftlint:disable force_cast
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            // swiftlint:enable force_cast
        }

        if let tableView_ = self.masterTableView {
            self.dataSource = DataSource(tableView: tableView_, cellForLocationCallback: { (inLocation) -> UITableViewCell in
                let cell: UITableViewCell
                let dequeuedCell = self.dataSource?.dequeueReusableCellWithIdentifier("Cell", sectionID: inLocation.sectionID, item: inLocation.item)
                if let cell_ = dequeuedCell {
                    cell = cell_
                } else {
                    cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
                }
                let rusher = inLocation.item
                cell.textLabel?.text = rusher.date.description
                cell.detailTextLabel?.text = rusher.identifier
                return cell
            })
            self.dataSource?.canEdit = { (atLocation:Location<Rusher>) -> Bool in return true }
            self.dataSource?.canMove = { (toLocation:Location<Rusher>) -> Bool in return true }
            self.dataSource?.willDelete = { (atLocation:Location<Rusher>) -> Void in
                print("will delete \(atLocation.sectionID) - \(atLocation.item.identifier)")
            }
            self.dataSource?.didChangeSectionIDs = { (inSectionIDs:Dictionary<String, Array<Rusher>>) -> Void in
            }

            self.dataSource?.sectionHeaderTitle = { return "header: \($0)" }
            self.dataSource?.sectionFooterTitle = { return "footer: \($0)" }

            self.dataSource?.updateSections(["first"], animated: false)

            self.testRush1()
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func newRusher() -> Rusher {
        let rusher = Rusher(inIdentifier: NSUUID().UUIDString)
        rusher.date = NSDate()
        return rusher
    }

    func insertNewObject(sender: AnyObject) {
        let rusher = self.newRusher()
        let sectionID: String
        if let sectionID_ = self.dataSource?.sections().last {
            sectionID = sectionID_
        } else {
            sectionID = NSUUID().UUIDString
            if let dataSource_ = self.dataSource {
                var sections = dataSource_.sections()
                sections.append(sectionID)
                dataSource_.updateSections(sections, animated: true)
            }
        }

        var rows = self.dataSource?.rowsForSection(sectionID)
        if rows == nil {
            rows = []
        }
        guard var rows_ = rows else {
            return
        }

        rows_.append(rusher)
        self.dataSource?.updateRows(rows_, section: sectionID, animated: true)
        if rows_.count > 5 {
            let newSectionID = NSUUID().UUIDString
            if let dataSource_ = self.dataSource {
                var sections = dataSource_.sections()
                sections.append(newSectionID)
                dataSource_.updateSections(sections, animated: true)
                dataSource_.updateRows([], section: newSectionID, animated: true)
            }
        }

    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            guard let (_, row) = self.dataSource?.sectionIDAndItemForIndexPath(indexPath) else {
                return
            }

            // swiftlint:disable force_cast
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            // swiftlint:enable force_cast
            controller.detailItem = row.date
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - rushing

    func testRush1() {
        for _ in 0 ..< 12 {
            self.insertNewObject(self)
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  500*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.testRush1b()
        }
    }

    func testRush1b() {
        if let firstSectionID = self.dataSource?.sections().first, var rows = self.dataSource?.rowsForSection(firstSectionID) {
            rows.removeAtIndex(rows.count - 1)
            rows.insert(newRusher(), atIndex: 3)

            self.dataSource?.updateRows(rows, section: firstSectionID, animated: true)
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  500*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.rush()
        }
    }

    func handleRushing(inSection sectionIndex: Int, insertIndex: Int, deleteIndex: Int, breathe: Breathing) {
        let sectionID: String

        if let sectionID_ = self.dataSource?.sections().optionalElementAtIndex(sectionIndex) {
            sectionID = sectionID_
        } else {
            sectionID = NSUUID().UUIDString
            if let dataSource_ = self.dataSource {
                var sections = dataSource_.sections()
                sections.append(sectionID)
                dataSource_.updateSections(sections, animated: true)
            }
        }

        guard var rows = self.dataSource?.rowsForSection(sectionID) else {
            return
        }

        if breathe != .Inhale && deleteIndex < rows.count {
            rows.removeAtIndex(deleteIndex)
        }
        if rows.count < insertIndex {
            rows.append(newRusher())
        } else {
            rows.insert(newRusher(), atIndex: insertIndex)
        }

        self.dataSource?.updateRows(rows, section: sectionID, animated: true)
    }

    private var count = 0
    private var breatheCount = 0
    private var breathe = Breathing.Inhale
    func rush() {
        if breathe == .Inhale {
            if breatheCount > 100 {
                breathe = .Exhale
            }
            breatheCount += 1
        } else {
            if breatheCount < 5 {
                breathe = .Inhale
            }
            breatheCount -= 1
        }

        count++
        let sectionIndex = (count % 37) * 3
        let sectionIndex2 = (count % 5) * 2

        let insertIndex = (count % 5)
        let deleteIndex = count % 3
        let insertIndex2 = (count % 7)
        let deleteIndex2 = count % 11

        handleRushing(inSection: sectionIndex, insertIndex: insertIndex, deleteIndex: deleteIndex, breathe: .Keep)
        handleRushing(inSection: sectionIndex2, insertIndex: insertIndex2, deleteIndex: deleteIndex2, breathe: breathe)

        if count < 1000 {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  150*1000*1000), dispatch_get_main_queue()) { () -> Void in
                self.rush()
            }
        }
    }

}
