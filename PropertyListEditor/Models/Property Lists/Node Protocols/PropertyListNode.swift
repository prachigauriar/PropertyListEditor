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

    /// Returns the child node at the specified index.
    /// :index: The index of the requested child. Asserts if the index is beyond the node’s bounds.
    func childNodeAtIndex(index: Int) -> PropertyListNode

    /// Returns the index of the specified child node. Returns nil if the child node cannot be found.
    /// :childNode: The child node to search for.
    func indexOfChildNode(childNode: PropertyListNode) -> Int?

    /// Returns an XML node representation of the node.
    func appendXMLNodeToParentElement(parentElement: NSXMLElement)
}
