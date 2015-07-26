//
//  PropertyListTree.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


/// A by-product of the `NSOutlineView` API is that its data must be modeled with objects (reference
/// types). This presents problems because `PropertyListItem` is a value type. Rather than losing
/// the benefits of enums and value semantics by changing `PropertyListItem` into a class, we use
/// instances of `PropertyListTree` and the `PropertyListTreeNodes` it contains as object proxies
/// for our data model’s property list items.
/// 
/// Each property list tree has a root *item* and a root *tree node*. The root item represents the 
/// actual data that the tree represents. While it is a value type and retains its value type
/// semantics, the property list tree that contains it is a reference type. Thus, all references to
/// the property list tree share the same root item. While this may seem obvious, it is the basic
/// reason why property list trees work. We use value types at the model level, but wrap them in a
/// reference type so that we can have many references to that same value.
///
/// A property list tree’s root tree node is the root of the the object proxy tree for the data in
/// the tree’s root item. That is, the item is the truth, and the node is the object proxy for the
/// truth. Care must be taken to keep these two trees in sync, but this is simple for the most part.
/// See the documentation for `PropertyListTreeNode` for more information.
class PropertyListTree: NSObject {
    /// The instance’s root property list item
    private(set) var rootItem: PropertyListItem

    /// The instance’s root property list tree node
    private(set) var rootNode: PropertyListTreeNode!


    /// Initializes a new property list tree with the specified root item.
    /// - parameter rootItem: The root item that the property list tree represents.
    init(rootItem: PropertyListItem) {
        self.rootItem = rootItem
        super.init()
        self.rootNode = PropertyListTreeNode(tree: self)
    }


    /// Initializes a new property list tree with a an empty dictionary as the root item.
    convenience override init() {
        self.init(rootItem: .DictionaryItem(PropertyListDictionary()))
    }


    /// Returns the property list tree node at the specified index path.
    /// - parameter indexPath: The index path. Raises an assertion if there is no item at the
    ///       specified index path.
    func nodeAtIndexPath(indexPath: NSIndexPath) -> PropertyListTreeNode {
        var treeNode = self.rootNode

        for index in indexPath.indexes {
            treeNode = treeNode.children[index]
        }

        return treeNode
    }


    /// Returns the item at the specified index path relative to the instance’s root item.
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    func itemAtIndexPath(indexPath: NSIndexPath) -> PropertyListItem {
        return self.rootItem.itemAtIndexPath(indexPath)
    }


    /// Sets the item at the specified index path relative to the instance’s root item.
    /// - parameter indexPath: The index path. Raises an assertion if any element of the index path
    ///       indexes into a scalar.
    func setItem(item: PropertyListItem, atIndexPath indexPath: NSIndexPath) {
        self.rootItem = self.rootItem.itemBySettingItem(item, atIndexPath: indexPath)
    }
}


/// Instances of `PropertyListTreeNode` acts as object proxies for property items in a property list
/// tree. Each node is meant to be used as an “item” for an `NSOutlineView` row.
///
/// A tree nodes can be thought of as an address to the property list item item it represents. Each
/// node has an index, a reference to its tree, and a reference to its parent node. Together, these
/// can be used to construct an index path to the node’s property list item relative to the root
/// item of the node’s tree. Each tree node also has an array of child nodes, which can be used to
/// get to the node for any item. We provide convenience methods for calculating a node’s index path;
/// getting and setting its item; and getting, adding, and removing child nodes.
///
/// Care should be taken to add and remove children from a child node when a corresponding change 
/// occurs on the node’s item. This can be done using `‑insertChildAtIndex:`, `‑removeChildAtIndex:`,
/// and `regenerateChildren`.
class PropertyListTreeNode: NSObject {
    /// The tree that the instance is in
    unowned let tree: PropertyListTree

    /// The instance’s parent node. This is `nil` when the instance is the root node.
    private(set) weak var parentNode: PropertyListTreeNode?

    /// The instance’s child nodes.
    private var children: [PropertyListTreeNode] = []

    /// The instance’s index.
    private(set) var index: Int? {
        didSet {
            self.cachedIndexPath = nil
            self.updateIndexesForChildrenInRange(0 ..< self.numberOfChildren)
        }
    }

    /// A cached version of the instance’s calculated index path. This is only calculated once
    /// provided that the instance’s index (or one of its ancestors’) doesn’t change.
    private var cachedIndexPath: NSIndexPath?


    /// The instance’s item.
    var item: PropertyListItem {
        get {
            return self.tree.itemAtIndexPath(self.indexPath)
        }

        set(item) {
            self.tree.setItem(item, atIndexPath: self.indexPath)
        }
    }


    /// Initializes a new root tree node with the specified tree.
    /// - parameter tree: The tree the node is in.
    init(tree: PropertyListTree) {
        self.tree = tree
        super.init()
        self.regenerateChildren()
    }


    /// Initializes a new tree node with the specified tree, parent node, and index.
    /// - parameter tree: The tree the node is in.
    /// - parameter parentNode: The node’s parent.
    /// - parameter index: The index of the node in its parent’s children array.
    init(tree: PropertyListTree, parentNode: PropertyListTreeNode, index: Int) {
        self.tree = tree
        self.parentNode = parentNode
        self.index = index
        super.init()
        self.regenerateChildren()
    }


    /// Returns the instance’s index path.
    var indexPath: NSIndexPath {
        if self.cachedIndexPath == nil {
            var indexes: [Int] = []

            var node: PropertyListTreeNode? = self
            while let index = node?.index {
                indexes.insert(index, atIndex: 0)
                node = node?.parentNode
            }

            self.cachedIndexPath = NSIndexPath(indexes: indexes, length: indexes.count)
        }

        return self.cachedIndexPath!
    }


    /// Whether the instance is the root node of its tree. This returns true if the instance has no
    /// parent.
    var isRootNode: Bool {
        return self.parentNode == nil
    }


    override var description: String {
        let indexPathString = (self.isRootNode ? "" : ".") + ".".join(self.indexPath.indexes.map { $0.description })
        return "<PropertyListTreeNode root\(indexPathString)>"
    }
    
    
    var hashValue: Int {
        return self.indexPath.hashValue
    }
    
    
    /// Regenerates the instance’s children nodes, replacing the previous ones with newly created
    /// ones.
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

    /// Returns whether the instance is expandable, i.e., whether it can have children.
    var expandable: Bool {
        return self.item.isCollection
    }


    /// Returns the number of child nodes the instance has.
    var numberOfChildren: Int {
        return self.children.count
    }


    /// Returns the instance’s child node with the specified index.
    /// - parameter index: The index of the child.
    /// - returns: The instance’s child tree node with the specified index.
    func childAtIndex(index: Int) -> PropertyListTreeNode {
        return self.children[index]
    }


    /// Returns the instance’s last child or `nil` if the instance has no children.
    var lastChild: PropertyListTreeNode? {
        return self.children.last
    }


    /// Inserts a new child node at the specified index.
    /// - parameter index: The index at which to insert the new child node.
    func insertChildAtIndex(index: Int) {
        self.children.insert(PropertyListTreeNode(tree: self.tree, parentNode: self, index: index), atIndex: index)
        self.updateIndexesForChildrenInRange(index ..< self.numberOfChildren)
    }


    /// Removes the child node at the specified index.
    /// - parameter index: The index from which to remove the child node.
    func removeChildAtIndex(index: Int) {
        self.children.removeAtIndex(index)
        self.updateIndexesForChildrenInRange(index ..< self.numberOfChildren)
    }


    /// Updates the indexes for the instance’s children whose index is in the specified range.
    /// - parameter indexRange: The range of child node indexes whose children need updated indexes.
    private func updateIndexesForChildrenInRange(indexRange: Range<Int>) {
        for i in indexRange {
            self.children[i].index = i
        }
    }
}
