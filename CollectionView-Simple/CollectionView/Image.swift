//
//  Image.swift
//  CollectionView
//
//  Created by Ruotger Deecke on 29.12.15.
//
//

import Foundation

class Image: DataItem {
    let identifier: String
    let title: String
    let image: UIImage
    let thumb: UIImage

    init(identifier: String, title: String, image: UIImage, thumb: UIImage) {
        self.identifier = identifier
        self.title = title
        self.image = image
        self.thumb = thumb
    }

}

extension Image : Equatable {

}

func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.identifier == rhs.identifier
}
