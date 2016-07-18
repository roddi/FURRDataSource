//
//  Reporting.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 13.07.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import Foundation

protocol Reporting {

    func setFailFunc(failFunc: (String) -> Void)
    func setWarnFunc(warnFunc: (String) -> Void)
    func setReportingLevel(level: DataSourceReportingLevel)

    #if swift(>=3.0)
    func setFunc(fail: ((String) -> Void )?)
    func setFunc(warn: ((String) -> Void )?)
    #endif

}
