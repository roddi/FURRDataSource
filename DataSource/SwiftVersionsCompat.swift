//
//  SwiftVersionsCompat.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 05.07.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import Foundation

#if swift(>=3.0)
    public typealias IndexPathway = IndexPath
#else
    public typealias IndexPathway = NSIndexPath
#endif
