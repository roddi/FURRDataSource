//
//  Reporting.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 13.07.16.
//  Copyright © 2016 Ruotger Deecke. All rights reserved.
//

import Foundation

protocol Reporting {

    #if !swift(>=3.0)
    @available(*, deprecated: 0.2) func setFailFunc(failFunc: (String) -> Void)
    @available(*, deprecated: 0.2) func setWarnFunc(warnFunc: (String) -> Void)
    @available(*, deprecated: 0.2) func setReportingLevel(level: DataSourceReportingLevel)
    #endif

    func setFunc(fail inFailFunc: ((String) -> Void )?)
    func setFunc(warn inWarnFunc: ((String) -> Void )?)
    func setReporting(level inLevel: DataSourceReportingLevel)
}
