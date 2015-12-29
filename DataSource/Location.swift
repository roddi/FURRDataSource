//
//  Location.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 28.12.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import Foundation

public struct Location<T> {
    public let sectionID: String
    public let item:T
}

public struct LocationWithOptionalItem<T> {
    public let sectionID: String
    public let item: T?

    public init (sectionID  inSectionID: String, item inItem: T?) {
        self.sectionID = inSectionID
        self.item = inItem
    }
}
