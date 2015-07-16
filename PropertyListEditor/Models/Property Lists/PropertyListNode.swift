//
//  PropertyListNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


/// PropertyListNode declares the data and behavior common to all types in a property list. Each node
/// can return if it is expandable or not and if so, return the number of children it has.
protocol PropertyListNode {
    /// Whether the node is expandable or not.
    var expandable: Bool { get }

    /// The number of children the node has.
    var numberOfChildren: Int { get }

    func childAtIndex(index: Int) -> AnyObject
}


/// PropertyListTypes
enum PropertyListType: String {
    case ArrayType, BooleanType, DataType, DateType, DictionaryType, NumberType, StringType
}


// MARK: Items and Item Nodes

/// PropertyListItems contain the data that is stored in a property list node. An item contains either
/// a PropertyListValue, a PropertyListArrayNode, or a PropertyListDictionaryNode
enum PropertyListItem {
    /// Indicates that the item is a value type, i.e., a boolean, data, date, number, or string.
    case Value(PropertyListValue)

    /// Indicates that the item is an array node
    case ArrayNode(PropertyListArrayNode)

    /// Indicates that the item is a dictionary node
    case DictionaryNode(PropertyListDictionaryNode)


    /// Indicates the property list type of the item
    var propertyListType: PropertyListType {
        switch self {
        case .ArrayNode:
            return .ArrayType
        case .DictionaryNode:
            return .DictionaryType
        case let .Value(value):
            switch value {
            case .BooleanValue:
                return .BooleanType
            case .DataValue:
                return .DataType
            case .DateValue:
                return .DateType
            case .NumberValue:
                return .NumberType
            case .StringValue:
                return .StringType
            }
        }
    }
}


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
    var numberOfChildren: Int {
        switch self.item {
        case .Value:
            return 0
        case let .ArrayNode(arrayNode):
            return arrayNode.numberOfChildren
        case let .DictionaryNode(dictionaryNode):
            return dictionaryNode.numberOfChildren
        }
    }


    func childAtIndex(index: Int) -> AnyObject {
        assert(index >= 0 && index < self.numberOfChildren, "index out of bounds")

        switch self.item {
        case .Value:
            assert(false)
        case let .ArrayNode(arrayNode):
            return arrayNode.childAtIndex(index)
        case let .DictionaryNode(dictionaryNode):
            return dictionaryNode.childAtIndex(index)
        }
    }

    
    var propertyListType: PropertyListType {
        return self.item.propertyListType
    }
}


// MARK: - Collection Nodes

protocol PropertyListCollectionNode: PropertyListNode {
    typealias ItemNodeType: PropertyListItemNode, AnyObject
    var children: [ItemNodeType] { get }
}


extension PropertyListCollectionNode {
    var expandable: Bool {
        return true
    }


    var numberOfChildren: Int {
        return self.children.count
    }


    func childAtIndex(index: Int) -> AnyObject {
        return self.children[index]
    }
}


// MARK: - Arrays

class PropertyListArrayItemNode: PropertyListItemNode {
    var index: Int
    var item: PropertyListItem


    init(index: Int, item: PropertyListItem) {
        self.index = index
        self.item = item
    }
}


class PropertyListArrayNode: PropertyListCollectionNode {
    var children: [PropertyListArrayItemNode] = []
}


// MARK: - Dictionaries

class PropertyListDictionaryItemNode: PropertyListItemNode {
    var key: String
    var item: PropertyListItem


    init(key: String, item: PropertyListItem) {
        self.key = key
        self.item = item
    }
}


class PropertyListDictionaryNode: PropertyListCollectionNode {
    var children: [PropertyListDictionaryItemNode] = []
}
