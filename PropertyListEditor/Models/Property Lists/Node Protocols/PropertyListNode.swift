//
//  PropertyListNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


/// PropertyListNode declares the data and behavior common to all nodes in a property list. Each node
/// can return if it is expandable or not and if so, return the number of children it has.
protocol PropertyListNode: AnyObject {
    /// Whether the node is expandable or not.
    var expandable: Bool { get }

    /// The number of children the node has.
    var numberOfChildNodes: Int { get }

    func childNodeAtIndex(index: Int) -> PropertyListNode

    func indexOfChildNode(childNode: PropertyListNode) -> Int?
}
