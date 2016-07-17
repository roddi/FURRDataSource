// swiftlint:disable line_length

//
//  SwiftVersionsCompat.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 05.07.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
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

import UIKit

enum CompatTableViewCellEditingStyle {
    case delete
    case insert
    case none
}

enum CompatTableViewCellStyle {
    case `default`
    case value1
    case value2
    case subtitle
}

enum CompatUITableViewStyle {
    case plain          // regular table view
    case grouped         // preferences style table view
}

#if swift(>=3.0)
    public typealias IndexPathway = IndexPath

    extension CompatTableViewCellEditingStyle {
        init(editingStyle: UITableViewCellEditingStyle) {
            switch editingStyle {
            case .delete:
                self = .delete
            case .insert:
                self = .insert
            case .none:
                self = .none
            }
        }
    }

    extension CompatTableViewCellStyle {
        func uiStyle() -> UITableViewCellStyle {
            switch self {
            case .default:
                return UITableViewCellStyle.default
            case .value1:
                return UITableViewCellStyle.value1
            case .value2:
                return UITableViewCellStyle.value2
            case .subtitle:
                return UITableViewCellStyle.subtitle
            }
        }
    }

    extension CompatUITableViewStyle {
        func uiStyle() -> UITableViewStyle {
            switch self {
            case .grouped:
                return UITableViewStyle.grouped
            case .plain:
                return UITableViewStyle.plain
            }
        }
    }

#else
    public typealias IndexPathway = NSIndexPath

    extension CompatTableViewCellEditingStyle {
        init(editingStyle: UITableViewCellEditingStyle) {
            switch editingStyle {
            case .Delete:
                self = .delete
            case .Insert:
                self = .insert
            case .None:
                self = .none
            }
        }
    }

    extension CompatTableViewCellStyle {
        func uiStyle() -> UITableViewCellStyle {
            switch self {
            case `default`:
                return UITableViewCellStyle.Default
            case value1:
                return UITableViewCellStyle.Value1
            case value2:
                return UITableViewCellStyle.Value2
            case subtitle:
                return UITableViewCellStyle.Subtitle
            }
        }
    }

    extension CompatUITableViewStyle {
        func uiStyle() -> UITableViewStyle {
            switch self {
            case .grouped:
                return UITableViewStyle.Grouped
            case .plain:
                return UITableViewStyle.Plain
            }
        }
    }

#endif
