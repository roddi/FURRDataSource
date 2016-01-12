//
//  ViewController.swift
//  CollectionView
//
//  Created by Ruotger Deecke on 29.12.15.
//
//

import UIKit

let kCellID = "cellID"                          // UICollectionViewCell storyboard id

class ViewController: UICollectionViewController {
    let kDetailedViewControllerID = "DetailView"    // view controller storyboard id

    var dataSource: CollectionDataSource<Image>?

    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        self.dataSource = CollectionDataSource(collectionView: self.collectionView!, cellForLocationCallback: self.cellGeneratorFunc())
        self.collectionView?.dataSource = self.dataSource

        var images: [Image] = Array()
        for i in [0..<32].flatten() {
            let numberString = "\(i)"
            if let uiimage = UIImage(named: numberString+"_full"),
                let thumb = UIImage(named: numberString) {
                    let image = Image(identifier: numberString, title: "Image "+numberString, image: uiimage, thumb: thumb)
                    images.append(image)
            }
        }

        self.dataSource?.updateSections(["section"], animated: true)
        self.dataSource?.updateRows(images, section: "section", animated: true)
    }

    func cellGeneratorFunc() -> ((inLocation: Location<Image>) -> UICollectionViewCell) {
        return { location in
            if let cell = self.dataSource?.dequeueReusableCellWithIdentifier(kCellID, sectionID: location.sectionID, item: location.item), let cell_ = cell as? Cell {
                cell_.label.text = location.item.title
                cell_.image.image = location.item.image
                return cell_
            } else {
                return UICollectionViewCell()
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let selectedLocation = self.dataSource?.selectedLocations().first,
                let detailViewController = segue.destinationViewController as? DetailViewController {
                detailViewController.image = selectedLocation.item.image
            }
        }
    }
}
