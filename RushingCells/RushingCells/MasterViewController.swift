//
//  MasterViewController.swift
//  RushingCells
//
//  Created by Deecke,Roddi on 26.08.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import UIKit

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

            //self.testRush1()
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
        var key = sectionIDs.last
        if key == nil {
            key = NSUUID().UUIDString
            //self.dataSource?.updateSections([key!], animated: true)
        }
        guard let sectionID = key else {
            return
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
    /*
    func testRush1() {
        for _ in 0 ..< 12 {
            self.insertNewObject(self)
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  500*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.testRush1b()
        }
    }

    func testRush1b() {
        objects.removeAtIndex(objects.count - 1)
        objects.insert(newRusher(), atIndex: 7)

        self.dataSource?.updateRows(objects, section: kOnlySectionID, animated: true)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  500*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.rush()
        }
    }

    private var count = 0
    private var grow = true
    func rush() {
        if grow {
            if objects.count > 100 {
                grow = false
            }
        }
        else {
            if objects.count < 5 {
                grow = true
            }
        }

        count++
        let insertIndex = (count % 5) * 2
        let deleteIndex = count % 13
        let insertIndex2 = (count % 37) * 3
        let deleteIndex2 = count % 3

        let growString = grow ? "grow" : "shrink"
        print("Rush! \(count) \(growString) -- rows: \(self.objects.count) ins: \(insertIndex)  del: \(deleteIndex)")

        if deleteIndex < objects.count {
            objects.removeAtIndex(deleteIndex)
        }
        if !grow && deleteIndex2 < objects.count {
            objects.removeAtIndex(deleteIndex2)
        }

        if objects.count < insertIndex {
            objects.append(newRusher())
        }
        else {
            objects.insert(newRusher(), atIndex: insertIndex)
        }

        if grow {
            if objects.count < insertIndex2 {
                objects.append(newRusher())
            }
            else {
                objects.insert(newRusher(), atIndex: insertIndex2)
            }
        }

        self.dataSource?.updateRows(objects, section: kOnlySectionID, animated: true)

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  350*1000*1000), dispatch_get_main_queue()) { () -> Void in
            self.rush()
        }
    }
*/
}
