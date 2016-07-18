//
//  TestHelpers.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 27.12.15.
//  Copyright © 2015 Ruotger Deecke. All rights reserved.
//

import Foundation

#if swift(>=3.0)
    func testHelper_indexListMapper() -> ([Int]) -> IndexPath {
        return { (indexList: [Int]) -> IndexPath in

            if indexList.count != 2 {
                return IndexPath(item: Int.max, section: Int.max)
            }
            return IndexPath(item: indexList[0], section: indexList[1])
        }
    }

#else
func testHelper_indexListMapper() -> ([Int]) -> NSIndexPath {
    return { (indexList: [Int]) -> NSIndexPath in

        if indexList.count != 2 {
            return NSIndexPath(forItem: Int.max, inSection: Int.max)
        }
        return NSIndexPath(forItem: indexList[0], inSection: indexList[1])
    }
}
#endif
