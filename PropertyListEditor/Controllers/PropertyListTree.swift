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
        self.rootTreeNode = PropertyListTreeNode(tree: self, indexPath: NSIndexPath())
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
    var indexPath: NSIndexPath
    var children: [PropertyListTreeNode] = []


    var parentNode: PropertyListTreeNode? {
        return self.indexPath.length > 0 ? self.tree.nodeAtIndexPath(self.indexPath.indexPathByRemovingLastIndex()) : nil
    }


    var index: Int? {
        return self.indexPath.lastIndex
    }


    var item: PropertyListItem {
        return self.tree.itemAtIndexPath(self.indexPath)
    }


    init(tree: PropertyListTree, indexPath: NSIndexPath) {
        self.tree = tree
        self.indexPath = indexPath
        super.init()
        self.regenerateChildren()
    }


    private func regenerateChildren() {
        self.children = (0 ..< self.numberOfChildren).map { PropertyListTreeNode(tree: self.tree, indexPath: self.indexPath.indexPathByAddingIndex($0)) }
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
        switch self.item {
        case let .ArrayItem(array):
            return array.elementCount
        case let .DictionaryItem(dictionary):
            return dictionary.elementCount
        default:
            return 0
        }
    }
}
