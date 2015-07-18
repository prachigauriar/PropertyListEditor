//
//  PropertyListArrayNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PropertyListArrayItemNode: PropertyListItemNode {
    private(set) var index: Int
    var item: PropertyListItem
    weak private(set) var parent: PropertyListArrayNode!


    init(index: Int, item: PropertyListItem, parent: PropertyListArrayNode) {
        self.index = index
        self.item = item
        self.parent = parent
    }
}


class PropertyListArrayNode: PropertyListNode {
    private var children: [PropertyListArrayItemNode] = []

    let expandable: Bool = true

    var numberOfChildNodes: Int {
        return self.children.count
    }


    func childNodeAtIndex(index: Int) -> PropertyListItemNode {
        return self.children[index]
    }


    func indexOfChildNode(childNode: PropertyListItemNode) -> Int? {
        guard let childNode = childNode as? PropertyListArrayItemNode else {
            return nil
        }

        return self.children.indexOf { childNode === $0 }
    }


    func appendXMLNodeToParentElement(parentElement: NSXMLElement) {
        let arrayElement = NSXMLElement(name: "array")
        for childNode in self.children {
            childNode.appendXMLNodeToParentElement(arrayElement)
        }

        parentElement.addChild(arrayElement)
    }
    

    // MARK: - Child Node Management

    func addChildNodeWithItem(item: PropertyListItem) -> PropertyListArrayItemNode {
        return self.insertChildNodeWithItem(item, atIndex: self.numberOfChildNodes)
    }


    func insertChildNodeWithItem(item: PropertyListItem, atIndex index: Int) -> PropertyListArrayItemNode {
        let childNode = PropertyListArrayItemNode(index: index, item: item, parent: self)
        self.children.insert(childNode, atIndex: index)
        self.updateChildIndexesStartingAtIndex(index)
        return childNode
    }


    func moveChildNodeAtIndex(oldIndex: Int, toIndex newIndex: Int) {
        let childNode = self.children[oldIndex]

        self.children.removeAtIndex(oldIndex)
        self.children.insert(childNode, atIndex: newIndex)

        let (minIndex, maxIndex) = oldIndex < newIndex ? (oldIndex, newIndex) : (newIndex, oldIndex)
        self.updateChildIndexesInRange(minIndex ... maxIndex)
    }


    func removeChildNodeAtIndex(index: Int) {
        self.children.removeAtIndex(index)
        self.updateChildIndexesStartingAtIndex(index)
    }


    func removeChildNode(childNode: PropertyListItemNode) {
        if let index = self.indexOfChildNode(childNode) {
            self.removeChildNodeAtIndex(index)
        }
    }


    private func updateChildIndexesStartingAtIndex(index: Int) {
        self.updateChildIndexesInRange(index ..< self.numberOfChildNodes)
    }


    private func updateChildIndexesInRange(range: Range<Int>) {
        for i in range {
            self.children[i].index = i
        }
    }
}
