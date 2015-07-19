//
//  PropertyListDictionaryNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PropertyListDictionaryItemNode: NSObject, PropertyListItemNode, NSCopying {
    private(set) var key: String
    var item: PropertyListItem
    weak private(set) var parent: PropertyListDictionaryNode!

    override var hashValue: Int {
        return self.key.hashValue ^ self.item.hashValue
    }


    override var description: String {
        return "[\(self.key)] = \(self.item)"
    }


    init(key: String, item: PropertyListItem, parent: PropertyListDictionaryNode) {
        self.key = key
        self.item = item
        self.parent = parent
    }


    func copyWithZone(zone: NSZone) -> AnyObject {
        return PropertyListDictionaryItemNode(key: self.key, item: self.item, parent: self.parent)
    }


    func appendXMLNodeToParentElement(parentElement: NSXMLElement) {
        parentElement.addChild(NSXMLElement(name: "key", stringValue: self.key))
        self.item.appendXMLNodeToParentElement(parentElement)
    }
}


func ==(lhs: PropertyListDictionaryItemNode, rhs: PropertyListDictionaryItemNode) -> Bool {
    return lhs.key == rhs.key && lhs.item == rhs.item && lhs.parent === rhs.parent
}


class PropertyListDictionaryNode: PropertyListNode, Hashable, CustomStringConvertible {
    typealias ChildNodeType = PropertyListDictionaryItemNode
    private var keySet: Set<String> = []
    private var children: [ChildNodeType] = []

    let expandable: Bool = true

    var numberOfChildNodes: Int {
        return self.children.count
    }


    var hashValue: Int {
        return self.children.count
    }


    var description: String {
        return "PropertyListDictionaryNode\n\t" + "\n\t".join(children.map{ $0.description })
    }


    func childNodeAtIndex(index: Int) -> PropertyListItemNode {
        return self.children[index]
    }


    func indexOfChildNode(childNode: PropertyListItemNode) -> Int? {
        guard let childNode = childNode as? ChildNodeType else {
            return nil
        }

        return self.children.indexOf { childNode == $0 }
    }


    func appendXMLNodeToParentElement(parentElement: NSXMLElement) {
        let dictionaryElement = NSXMLElement(name: "dict")
        for childNode in self.children {
            childNode.appendXMLNodeToParentElement(dictionaryElement)
        }
        
        parentElement.addChild(dictionaryElement)
    }


    // MARK: - Child Node Management

    func containsChildNodeWithKey(key: String) -> Bool {
        return self.keySet.contains(key)
    }


    func addChildNodeWithKey(key: String, item: PropertyListItem) -> ChildNodeType {
        return self.insertChildNodeWithKey(key, item: item, atIndex: self.numberOfChildNodes)
    }


    func insertChildNode(childNode: ChildNodeType, atIndex index: Int) {
        assert(!self.keySet.contains(childNode.key), "dictionary contains key \(childNode.key)")
        self.children.insert(childNode, atIndex: index)
        self.keySet.insert(childNode.key)
    }

    
    func insertChildNodeWithKey(key: String, item: PropertyListItem, atIndex index: Int) -> ChildNodeType {
        let childNode = PropertyListDictionaryItemNode(key: key, item: item, parent: self)
        self.insertChildNode(childNode, atIndex: index)
        return childNode
    }


    func moveChildNodeAtIndex(oldIndex: Int, toIndex newIndex: Int) {
        let childNode = self.children[oldIndex]
        self.children.removeAtIndex(oldIndex)
        self.children.insert(childNode, atIndex: newIndex)
    }


    func removeChildNodeAtIndex(index: Int) {
        let childNode = self.children.removeAtIndex(index)
        self.keySet.remove(childNode.key)
    }


    func removeChildNode(childNode: ChildNodeType) {
        if let index = self.indexOfChildNode(childNode) {
            self.removeChildNodeAtIndex(index)
        }
    }

    
    func setKey(key: String, forChildNodeAtIndex index: Int) {
        assert(!self.keySet.contains(key), "dictionary contains key \(key)")
        self.keySet.remove(self.children[index].key)
        self.children[index].key = key
        self.keySet.insert(key)
    }
}


func ==(lhs: PropertyListDictionaryNode, rhs: PropertyListDictionaryNode) -> Bool {
    return lhs.children == rhs.children
}

