//
//  DataItemProtocol.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 28.12.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import Foundation

public protocol DataItem: Equatable {
    var identifier: String { get }
}
