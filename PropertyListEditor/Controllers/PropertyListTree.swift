//
//  PropertyListTree.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class PropertyListTree: NSObject {
    private(set) var rootItem: PropertyListItem
    private(set) var rootTreeNode: PropertyListTreeNode!


    init(rootItem: PropertyListItem) {
        self.rootItem = rootItem
        super.init()
        self.rootTreeNode = PropertyListTreeNode(tree: self, parentNode: nil, index: nil)
    }


    convenience override init() {
        self.init(rootItem: .DictionaryItem(PropertyListDictionary()))
    }


    func nodeAtIndexPath(indexPath: NSIndexPath) -> PropertyListTreeNode {
        var treeNode = rootTreeNode

        for index in indexPath.indexes {
            treeNode = treeNode.children[index]
        }

        return treeNode
    }


    func itemAtIndexPath(indexPath: NSIndexPath) -> PropertyListItem {
        return self.rootItem.itemAtIndexPath(indexPath)
    }


    func setItem(item: PropertyListItem, atIndexPath indexPath: NSIndexPath) {
        self.rootItem = self.rootItem.itemBySettingItem(item, atIndexPath: indexPath)
    }
}


class PropertyListTreeNode: NSObject {
    unowned let tree: PropertyListTree
    weak var parentNode: PropertyListTreeNode?
    private(set) var index: Int?
    private(set) var children: [PropertyListTreeNode] = []


    var indexPath: NSIndexPath {
        var indexes: [Int] = []

        var node: PropertyListTreeNode! = self
        while let index = node?.index {
            indexes.insert(index, atIndex: 0)
            node = node.parentNode
        }

        return indexes.count > 0 ? NSIndexPath(indexes: &indexes, length: indexes.count) : NSIndexPath()
    }


    var item: PropertyListItem {
        get {
            return self.tree.itemAtIndexPath(self.indexPath)
        }

        set(item) {
            self.tree.setItem(item, atIndexPath: self.indexPath)
        }
    }


    init(tree: PropertyListTree, parentNode: PropertyListTreeNode?, index: Int?) {
        self.tree = tree
        self.parentNode = parentNode
        self.index = index
        super.init()
        self.regenerateChildren()
    }


    func regenerateChildren() {
        let elementCount: Int
        switch self.item {
        case let .ArrayItem(array):
            elementCount = array.elementCount
        case let .DictionaryItem(dictionary):
            elementCount = dictionary.elementCount
        default:
            return
        }

        self.children = (0 ..< elementCount).map { (i: Int) in PropertyListTreeNode(tree: self.tree, parentNode: self, index: i) }
    }


    // MARK: - NSOutlineView Helpers

    var expandable: Bool {
        switch self.item {
        case .ArrayItem, .DictionaryItem:
            return true
        default:
            return false
        }
    }


    var numberOfChildren: Int {
        return self.children.count
    }


    func insertChildAtIndex(index: Int) {
        self.children.insert(PropertyListTreeNode(tree: self.tree, parentNode: self, index: index), atIndex: index)
    }


    func removeChildAtIndex(index: Int) {
        self.children.removeAtIndex(index)
    }
}
