// swiftlint:disable line_length
//
//  MasterViewController.swift
//  RushingCells
//
//  Created by Deecke,Roddi on 26.08.15.
//  Copyright © 2015-2016 Ruotger Deecke. All rights reserved.
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

// This is sample code, so I disable all of this.

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable function_body_length

import UIKit

enum Breathing: String {
    case inhale, exhale, keep
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController?
    @IBOutlet weak var masterTableView: UITableView?
    var dataSource: TableDataSource<Rusher>?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewObject(sender:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            // swiftlint:disable force_cast
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            // swiftlint:enable force_cast
        }

        if let tableView_ = self.masterTableView {
            self.dataSource = TableDataSource(tableView: tableView_, cellForLocationCallback: { (inLocation) -> UITableViewCell in
                let cell: UITableViewCell
                let dequeuedCell = self.dataSource?.dequeueReusableCell(withIdentifier: "Cell", sectionID: inLocation.sectionID, item: inLocation.item)
                if let cell_ = dequeuedCell {
                    cell = cell_
                } else {
                    cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "Cell")
                }
                let rusher = inLocation.item
                cell.textLabel?.text = rusher.date.description
                cell.detailTextLabel?.text = rusher.identifier
                return cell
            })
            self.dataSource?.canEditAtLocation = { (atLocation: Location<Rusher>) -> Bool in return true }
            self.dataSource?.canMoveToLocation = { (toLocation: Location<Rusher>) -> Bool in return true }
            self.dataSource?.willDeleteAtLocation = { (atLocation: Location<Rusher>) -> Void in
                print("will delete \(atLocation.sectionID) - \(atLocation.item.identifier)")
            }
            self.dataSource?.setFunc(didChangeSectionIDsFunc: { (_: [String: [Rusher]]) -> Void in
            })

            self.dataSource?.sectionHeaderTitleForSectionID = { return "header: \($0)" }
            self.dataSource?.sectionFooterTitleForSectionID = { return "footer: \($0)" }

            let deleteAction = TableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "XXX", handler: { (_: TableViewRowAction, location: Location<Rusher>) in
                print("delete \(location.item.identifier)")
                self.dataSource?.deleteItems([location.item])
            })
            deleteAction.title = "Nuke it!"
            deleteAction.backgroundColor = UIColor.brown
            deleteAction.backgroundEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: UIBlurEffectStyle.extraLight))

            self.dataSource?.editActionsForLocation = { (location: Location<Rusher>) -> [TableViewRowAction<Rusher>] in
                return [deleteAction]
            }

            self.dataSource?.update(sections: ["first"], animated: false)

            self.testRush1()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func newRusher() -> Rusher {
        let rusher = Rusher(inIdentifier: UUID().uuidString)
        rusher.date = Date()
        return rusher
    }

    func insertNewObject(sender: AnyObject) {
        let rusher = self.newRusher()
        let sectionID: String
        if let sectionID_ = self.dataSource?.sections().last {
            sectionID = sectionID_
        } else {
            sectionID = UUID().uuidString
            if let dataSource_ = self.dataSource {
                var sections = dataSource_.sections()
                sections.append(sectionID)
                dataSource_.update(sections: sections, animated: true)
            }
        }

        var rows = self.dataSource?.rows(forSection: sectionID)
        if rows == nil {
            rows = []
        }
        guard var rows_ = rows else {
            return
        }

        rows_.append(rusher)
        self.dataSource?.update(rows: rows_, section: sectionID, animated: true)
        if rows_.count > 5 {
            let newSectionID = UUID().uuidString
            if let dataSource_ = self.dataSource {
                var sections = dataSource_.sections()
                sections.append(newSectionID)
                dataSource_.update(sections: sections, animated: true)
                dataSource_.update(rows: [], section: newSectionID, animated: true)
            }
        }

    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                return
            }
            guard let (_, row) = self.dataSource?.sectionIDAndItem(indexPath: indexPath) else {
                return
            }

            // swiftlint:disable force_cast
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            // swiftlint:enable force_cast
            controller.detailItem = row.date as AnyObject
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - rushing

    func testRush1() {
        for _ in 0 ..< 12 {
            self.insertNewObject(sender: self)
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 500*1000*1000)) {
            () -> Void in
            self.testRush1b()
        }
    }

    func testRush1b() {
        if let firstSectionID = self.dataSource?.sections().first, var rows = self.dataSource?.rows(forSection: firstSectionID) {
            rows.remove(at: rows.count - 1)
            rows.insert(newRusher(), at: 3)

            self.dataSource?.update(rows: rows, section: firstSectionID, animated: true)
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 500*1000*1000)) { () -> Void in
            self.rush()
        }
    }

    func handleRushing(inSection sectionIndex: Int, insertIndex: Int, deleteIndex: Int, breathe: Breathing) {
        let sectionID: String

        if let sectionID_ = self.dataSource?.sections().optionalElement(index: sectionIndex) {
            sectionID = sectionID_
        } else {
            sectionID = NSUUID().uuidString
            if let dataSource_ = self.dataSource {
                var sections = dataSource_.sections()
                sections.append(sectionID)
                dataSource_.update(sections: sections, animated: true)
            }
        }

        guard var rows = self.dataSource?.rows(forSection: sectionID) else {
            return
        }

        if breathe != .inhale && deleteIndex < rows.count {
            rows.remove(at: deleteIndex)
        }
        if rows.count < insertIndex {
            rows.append(newRusher())
        } else {
            rows.insert(newRusher(), at: insertIndex)
        }

        self.dataSource?.update(rows: rows, section: sectionID, animated: true)
    }

    private var count = 0
    private var breatheCount = 0
    private var breathe = Breathing.inhale
    func rush() {
        if breathe == .inhale {
            if breatheCount > 100 {
                breathe = .exhale
            }
            breatheCount += 1
        } else {
            if breatheCount < 5 {
                breathe = .inhale
            }
            breatheCount -= 1
        }

        count += 1
        let sectionIndex = (count % 37) * 3
        let sectionIndex2 = (count % 5) * 2

        let insertIndex = (count % 5)
        let deleteIndex = count % 3
        let insertIndex2 = (count % 7)
        let deleteIndex2 = count % 11

        handleRushing(inSection: sectionIndex, insertIndex: insertIndex, deleteIndex: deleteIndex, breathe: .keep)
        handleRushing(inSection: sectionIndex2, insertIndex: insertIndex2, deleteIndex: deleteIndex2, breathe: breathe)

        if count < 1000 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 150*1000*1000)) { () -> Void in
                self.rush()
            }
        }
    }

}
