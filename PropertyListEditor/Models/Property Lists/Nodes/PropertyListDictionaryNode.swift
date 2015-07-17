//
//  PropertyListDictionaryNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PropertyListDictionaryItemNode: PropertyListItemNode {
    private(set) var key: String
    var item: PropertyListItem
    weak private(set) var parent: PropertyListDictionaryNode!

    
    init(key: String, item: PropertyListItem, parent: PropertyListDictionaryNode) {
        self.key = key
        self.item = item
        self.parent = parent
    }
}


class PropertyListDictionaryNode: PropertyListNode {
    private var keySet: Set<String> = []
    private var children: [PropertyListDictionaryItemNode] = []

    let expandable: Bool = true

    var numberOfChildNodes: Int {
        return self.children.count
    }
    

    func childNodeAtIndex(index: Int) -> PropertyListNode {
        return self.children[index]
    }


    func indexOfChildNode(childNode: PropertyListNode) -> Int? {
        guard let childNode = childNode as? PropertyListDictionaryItemNode else {
            return nil
        }

        return self.children.indexOf { childNode === $0 }
    }


    // MARK: - Child Node Management

    func containsChildNodeWithKey(key: String) -> Bool {
        return self.keySet.contains(key)
    }


    func addChildNodeWithKey(key: String, item: PropertyListItem) -> PropertyListDictionaryItemNode {
        return self.insertChildNodeWithKey(key, item: item, atIndex: self.numberOfChildNodes)
    }


    func insertChildNodeWithKey(key: String, item: PropertyListItem, atIndex index: Int) -> PropertyListDictionaryItemNode {
        assert(!self.keySet.contains(key), "dictionary contains key \(key)")

        let childNode = PropertyListDictionaryItemNode(key: key, item: item, parent: self)
        self.children.insert(childNode, atIndex: index)
        self.keySet.insert(key)
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


    func setKey(key: String, forChildNodeAtIndex index: Int) {
        assert(!self.keySet.contains(key), "dictionary contains key \(key)")
        self.children[index].key = key
    }
}
