// swiftlint:disable line_length
//
//  ViewController.swift
//  CollectionView
//
//  Created by Ruotger Deecke on 29.12.15.
//
//
// Copyright (C) 2015-2016 Ruotger Deecke
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
        for idx in [0..<32].joined() {
            let numberString = "\(idx)"
            if let uiimage = UIImage(named: numberString+"_full"), let thumb = UIImage(named: numberString) {
                    let image = Image(identifier: numberString, title: "Image "+numberString, image: uiimage, thumb: thumb)
                    images.append(image)
            }
        }

        self.dataSource?.update(sections: ["section"], animated: true)
        self.dataSource?.update(rows: images, section: "section", animated: true)
    }

    func cellGeneratorFunc() -> ((_ inLocation: Location<Image>) -> UICollectionViewCell) {
        return { location in
            guard let cell = self.dataSource?.dequeueReusableCell(withReuseIdentifier: kCellID, sectionID: location.sectionID, item: location.item) as? Cell else {
                return UICollectionViewCell()
            }

            cell.label.text = location.item.title
            cell.image.image = location.item.image
            return cell
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let selectedLocation = self.dataSource?.selectedLocations().first,
                let detailViewController = segue.destination as? DetailViewController {
                detailViewController.image = selectedLocation.item.image
            }
        }
    }
}
