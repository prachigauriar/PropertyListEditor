//
//  PropertyListItemNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


/// PropertyListItemNode declares the data and behavior common to property list nodes that have a single
/// item. Each item node has a single property called item which stores the item in the node.
protocol PropertyListItemNode: PropertyListNode {
    /// The node’s item.
    var item: PropertyListItem { get set }

    /// The node’s item’s type
    var propertyListType: PropertyListType { get }
}


extension PropertyListItemNode {
    /// True if and only if the node’s item is a collection node that is expandable
    var expandable: Bool {
        switch self.item {
        case .Value:
            return false
        case let .ArrayNode(arrayNode):
            return arrayNode.expandable
        case let .DictionaryNode(dictionaryNode):
            return dictionaryNode.expandable
        }
    }


    /// If the node’s item is a collection node, the collection node’s number of children; 0 otherwise.
    var numberOfChildNodes: Int {
        switch self.item {
        case .Value:
            return 0
        case let .ArrayNode(arrayNode):
            return arrayNode.numberOfChildNodes
        case let .DictionaryNode(dictionaryNode):
            return dictionaryNode.numberOfChildNodes
        }
    }


    var propertyListType: PropertyListType {
        return self.item.propertyListType
    }


    func childNodeAtIndex(index: Int) -> PropertyListNode {
        assert(index >= 0 && index < self.numberOfChildNodes, "index out of bounds")

        switch self.item {
        case .Value:
            assert(false)
        case let .ArrayNode(arrayNode):
            return arrayNode.childNodeAtIndex(index)
        case let .DictionaryNode(dictionaryNode):
            return dictionaryNode.childNodeAtIndex(index)
        }
    }
    

    func indexOfChildNode(childNode: PropertyListNode) -> Int? {
        switch self.item {
        case .Value:
            return nil
        case let .ArrayNode(arrayNode):
            return arrayNode.indexOfChildNode(childNode)
        case let .DictionaryNode(dictionaryNode):
            return dictionaryNode.indexOfChildNode(childNode)
        }
    }
}
