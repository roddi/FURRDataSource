//
//  MasterViewController.swift
//  RushingCells
//
//  Created by Deecke,Roddi on 26.08.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit

enum Breathing: String {
    case Inhale, Exhale, Keep
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [String:[Rusher]]()
    var sectionIDs = [String]()
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
                }
                else {
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
            self.dataSource?.didChangeSectionIDs = { (inSectionIDs:Dictionary<String,Array<Rusher>>) -> Void in
                for (key,object) in inSectionIDs {
                    self.objects.updateValue(object, forKey: key)
                }
            }

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
        if let sectionID_ = sectionIDs.last {
            sectionID = sectionID_
        }
        else {
            sectionID = NSUUID().UUIDString
            self.sectionIDs.append(sectionID)
            self.dataSource?.updateSections(self.sectionIDs, animated: true)
        }

        var rows = self.objects[sectionID]
        if rows == nil {
            rows = []
        }
        guard var rows_ = rows else {
            return
        }

        rows_.append(rusher)
        self.objects.updateValue(rows_, forKey: sectionID)
        self.dataSource?.updateRows(rows_, section: sectionID, animated: true)
        if rows_.count > 5 {
            let newSectionID = NSUUID().UUIDString
            self.sectionIDs.append(newSectionID)
            self.dataSource?.updateSections(self.sectionIDs, animated: true)
            self.objects.updateValue([], forKey: newSectionID)
            self.dataSource?.updateRows([], section: newSectionID, animated: true)
        }

    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            let sectionID = self.sectionIDs[indexPath.section]
            guard let object = objects[sectionID]?.optionalElementAtIndex(indexPath.row) else {
                return
            }
            // swiftlint:disable force_cast
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            // swiftlint:enable force_cast
            controller.detailItem = object.date
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
        if let firstSectionID = self.sectionIDs.first, var rows = self.objects[firstSectionID] {
            rows.removeAtIndex(rows.count - 1)
            rows.insert(newRusher(), atIndex: 3)
            self.objects[firstSectionID] = rows

            self.dataSource?.updateRows(rows, section: firstSectionID, animated: true)
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  500*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.rush()
        }
    }

    func handleRushing(inSection sectionIndex: Int, insertIndex: Int, deleteIndex: Int, breathe: Breathing) {
        let sectionID: String

        if let sectionID_ = self.sectionIDs.optionalElementAtIndex(sectionIndex) {
            sectionID = sectionID_
        }
        else {
            sectionID = NSUUID().UUIDString
            self.sectionIDs.append(sectionID)
            self.objects[sectionID] = []
            self.dataSource?.updateSections(self.sectionIDs, animated: true)
        }

        guard var rows = self.objects[sectionID] else {
            return
        }

        if breathe != .Inhale && deleteIndex < rows.count {
            rows.removeAtIndex(deleteIndex)
        }
        if rows.count < insertIndex {
            rows.append(newRusher())
        }
        else {
            rows.insert(newRusher(), atIndex: insertIndex)
        }
        self.objects[sectionID] = rows

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
        }
        else {
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

        print("Rush! \(count) \(breathe.rawValue) -- rows: \(self.objects.count) ins: \(insertIndex)  del: \(deleteIndex)")

        handleRushing(inSection: sectionIndex, insertIndex: insertIndex, deleteIndex: deleteIndex, breathe: .Keep)
        handleRushing(inSection: sectionIndex2, insertIndex: insertIndex2, deleteIndex: deleteIndex2, breathe: breathe)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  350*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.rush()
        }
    }

}
