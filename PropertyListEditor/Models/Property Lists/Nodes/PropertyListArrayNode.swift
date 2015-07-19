//
//  PropertyListArrayNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PropertyListArrayItemNode: NSObject, PropertyListItemNode, NSCopying {
    private(set) var index: Int
    var item: PropertyListItem
    weak private(set) var parent: PropertyListArrayNode!

    override var hashValue: Int {
        return self.index ^ self.item.hashValue
    }


    override var description: String {
        return "[\(self.index)] = \(self.item)"
    }


    init(index: Int, item: PropertyListItem, parent: PropertyListArrayNode) {
        self.index = index
        self.item = item
        self.parent = parent
    }


    func copyWithZone(zone: NSZone) -> AnyObject {
        return PropertyListArrayItemNode(index: self.index, item: self.item, parent: self.parent)
    }
}


func ==(lhs: PropertyListArrayItemNode, rhs: PropertyListArrayItemNode) -> Bool {
    return lhs.index == rhs.index && lhs.item == rhs.item && lhs.parent === rhs.parent
}


class PropertyListArrayNode: PropertyListNode, Hashable, CustomStringConvertible {
    typealias ChildNodeType = PropertyListArrayItemNode

    private var children: [ChildNodeType] = []
    let expandable: Bool = true

    var numberOfChildNodes: Int {
        return self.children.count
    }


    var hashValue: Int {
        return self.children.count
    }


    var description: String {
        return "PropertyListArrayNode\n\t" + "\n\t".join(children.map{ $0.description })
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
        let arrayElement = NSXMLElement(name: "array")
        for childNode in self.children {
            childNode.appendXMLNodeToParentElement(arrayElement)
        }

        parentElement.addChild(arrayElement)
    }
    

    // MARK: - Child Node Management

    func addChildNodeWithItem(item: PropertyListItem) -> ChildNodeType {
        return self.insertChildNodeWithItem(item, atIndex: self.numberOfChildNodes)
    }


    func insertChildNode(childNode: ChildNodeType, atIndex index: Int) {
        self.children.insert(childNode, atIndex: index)
        self.updateChildIndexesStartingAtIndex(index)
    }


    func insertChildNodeWithItem(item: PropertyListItem, atIndex index: Int) -> ChildNodeType {
        let childNode = PropertyListArrayItemNode(index: index, item: item, parent: self)
        self.insertChildNode(childNode, atIndex: index)
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


    func removeChildNode(childNode: ChildNodeType) {
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


func ==(lhs: PropertyListArrayNode, rhs: PropertyListArrayNode) -> Bool {
    return lhs.children == rhs.children
}
