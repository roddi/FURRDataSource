//
//  TestHelpers.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 27.12.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import Foundation

func testHelper_indexListMapper() -> ([Int]) -> NSIndexPath {
    return { (indexList: [Int]) -> NSIndexPath in

        if indexList.count != 2 {
            return NSIndexPath(forItem: Int.max, inSection: Int.max)
        }
        return NSIndexPath(forItem: indexList[0], inSection: indexList[1])
    }
}
