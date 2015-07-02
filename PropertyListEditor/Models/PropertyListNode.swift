//
//  PropertyListNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/1/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


protocol PropertyListNode {

}


// MARK: Single Value Nodes

protocol PropertyListSingleValueNode {

}


// MARK: Compound Value Nodes

protocol PropertyListCompoundValueNode {
    var childNodeCount: Int { get }

    func keyForChildAtIndex(index: Int) -> String
    func childAtIndex(index: Int) -> PropertyListNode
}


// MARK: Arrays

class ArrayItemNode: PropertyListNode {
    var valueNode: PropertyListNode

    init(valueNode: PropertyListNode) {
        self.valueNode = valueNode
    }
}


class ArrayNode: PropertyListCompoundValueNode {
    var childNodes: [ArrayItemNode] = []

    var childNodeCount:Int {
        return self.childNodes.count
    }


    func keyForChildAtIndex(index: Int) -> String {
        assert(index >= 0 && index < childNodeCount)
        return "Item \(index)"
    }


    func childAtIndex(index: Int) -> PropertyListNode {
        assert(index >= 0 && index < childNodeCount)
        return self.childNodes[index]
    }
}


// MARK: - Dictionaries

class DictionaryItemNode: PropertyListNode {
    var key: String
    var valueNode: PropertyListNode

    init(key: String, valueNode: PropertyListNode) {
        self.key = key
        self.valueNode = valueNode
    }
}


class DictionaryNode: PropertyListCompoundValueNode {
    var childNodes: [DictionaryItemNode] = []

    var childNodeCount:Int {
        return self.childNodes.count
    }


    func keyForChildAtIndex(index: Int) -> String {
        assert(index >= 0 && index < childNodeCount)
        return self.childNodes[index].key
    }


    func childAtIndex(index: Int) -> PropertyListNode {
        assert(index >= 0 && index < childNodeCount)
        return self.childNodes[index]
    }
}
