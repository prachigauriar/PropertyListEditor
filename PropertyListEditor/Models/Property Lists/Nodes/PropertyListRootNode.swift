//
//  PropertyListRootNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


/// PropertyListRootNode objects represent the root node in a property list. It simply has a single property
/// list item.
class PropertyListRootNode: PropertyListItemNode {
    var item: PropertyListItem


    /// Creates a new PropertyListRootNode with the specified item.
    /// :item: The root node’s item
    init(item: PropertyListItem) {
        self.item = item
    }


    /// Creates a new PropertyListRootNode with the specified property list object.
    /// Throws if the property list object can’t be converted into a property list item.
    /// :propertyListObject: The property list object whose item representation should be the root node’s item.
    convenience init(propertyListObject: PropertyListItemConvertible) throws {
        let item = try propertyListObject.propertyListItem()
        self.init(item: item)
    }
}
