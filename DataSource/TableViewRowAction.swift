//
//  TableViewRowAction.swift
//  FURRDataSource
//
//  Created by Ruotger Deecke on 13.8.17.
//  Copyright © 2017 Ruotger Deecke. All rights reserved.
//

import UIKit

public class TableViewRowAction <T> where T: DataItem {
    // we cannot create this as part of the initial initialization because it needs self. So it must be optional
    internal var uiTableViewRowAction: UITableViewRowAction?

    private let handler: (TableViewRowAction, Location<T>) -> Void
    internal var engine: DataSourceEngine<T>?

    public var style: UITableViewRowActionStyle {
        return uiTableViewRowAction?.style ?? .default
    }
    public var title: String? {
        get {
            return uiTableViewRowAction?.title
        } set (value) {
            uiTableViewRowAction?.title = value
        }
    }
    public var backgroundColor: UIColor? {
        get {
            return uiTableViewRowAction?.backgroundColor
        } set (value) {
            uiTableViewRowAction?.backgroundColor = value
        }
    }
    public var backgroundEffect: UIVisualEffect? {
        get {
            return uiTableViewRowAction?.backgroundEffect
        } set (value) {
            uiTableViewRowAction?.backgroundEffect = value
        }
    }

    public init(style: UITableViewRowActionStyle, title: String?, handler: @escaping (TableViewRowAction, Location<T>) -> Void) {
        self.handler = handler

        uiTableViewRowAction = UITableViewRowAction(style: style, title: title, handler: handle)
    }

    func handle(action: UITableViewRowAction, indexPath: IndexPath) {
        guard let engine = engine else {
            assertionFailure("must have an engine otherwise I can't resolve the location")
            return
        }

        guard let location = engine.location(forIndexPath: indexPath) else {
            assertionFailure("I cannot resolve the location")
            return
        }

        handler(self, location)
    }
}
