//
//  PropertyListDocument.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/1/2015.
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

import Cocoa


/// A `PropertyListDocument` instance synchronizes the changes between a property list document window
/// and its backing data model. It manages opening and saving property list documents, displaying the
/// document’s UI (an outline view), and synchronizing edits between the UI and the property list tree
/// that contains its data.
class PropertyListDocument : NSDocument, NSOutlineViewDataSource, NSOutlineViewDelegate {
    /// The instance’s property list tree. This is the model object that the controller manages.
    private var tree: PropertyListTree! {
        didSet {
            propertyListOutlineView?.reloadData()
        }
    }


    /// The instance’s outline view.
    @IBOutlet weak var propertyListOutlineView: NSOutlineView!


    override init() {
        tree = PropertyListTree()
        super.init()
    }


    deinit {
        // Failing to unset the data source here results in a stray delegate message sent to the
        // zombie PropertyListDocument. While there may be a more correct solution, I’ve yet to find
        // it.
        propertyListOutlineView?.dataSource = nil
        propertyListOutlineView?.delegate = nil
    }


    // MARK: - NSDocument Methods

    override var windowNibName: NSNib.Name? {
        return .propertyListDocument
    }


    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        propertyListOutlineView.expandItem(nil, expandChildren: true)
    }


    override func data(ofType typeName: String) throws -> Data {
        return tree.rootItem.propertyListXMLDocumentData() as Data
    }


    override func read(from data: Data, ofType typeName: String) throws {
        var format: PropertyListSerialization.PropertyListFormat = .xml
        let propertyListObject = try PropertyListSerialization.propertyList(from: data, options: [], format: &format) as! PropertyListItemConvertible

        let rootItem: PropertyListItem

        // If the document is in binary or ASCII format, convert the NSPropertyListSerialization
        // output into a property list item. If it’s in XML, use our custom XML reader so that our
        // dictionary keys are in the same order as the XML.
        if format != .xml {
            rootItem = try propertyListObject.propertyListItem()
        } else {
            // If an error occurs in our XML reader, fall back on the property list object that
            // NSPropertyListSerialization already successfully produced. This should hopefully
            // never happen.
            do {
                rootItem = try PropertyListXMLReader(XMLData: data).readData()
            } catch let error {
                NSLog("An error occurred while reading property list XML: \(error). Falling back on Apple’s implementation.")
                rootItem = try propertyListObject.propertyListItem()
            }
        }

        tree = PropertyListTree(rootItem: rootItem)
    }


    // MARK: - Outline View Data Source

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1
        }

        let treeNode = item as! PropertyListTreeNode
        return treeNode.numberOfChildren
    }


    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let treeNode = item as! PropertyListTreeNode
        return treeNode.isExpandable
    }


    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return tree.rootNode as Any
        }

        let treeNode = item as! PropertyListTreeNode
        return treeNode.child(at: index)
    }


    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        let treeNode = item as! PropertyListTreeNode
        let tableColumnIdentifier = tableColumn!.identifier

        switch tableColumnIdentifier {
        case .keyColumn:
            return key(of: treeNode)
        case .typeColumn:
            return typePopUpMenuItemIndex(of: treeNode)
        case .valueColumn:
            return value(of: treeNode)
        default:
            preconditionFailure("Unknown table column")
        }
    }


    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        let treeNode = item as! PropertyListTreeNode
        let tableColumnIdentifier = tableColumn!.identifier
        let propertyListObject = object as! PropertyListItemConvertible

        switch tableColumnIdentifier {
        case .keyColumn:
            setKey(object as! String, of: treeNode)
        case .typeColumn:
            let type = PropertyListType(typePopUpMenuItemIndex: object as! Int)!
            setType(type, of: treeNode)
        case .valueColumn:
            let item: PropertyListItem

            // The two cases here are the value being set by a pop-up button or the value being returned directly
            if case let nodeItem = treeNode.item,
                let valueConstraint = nodeItem.valueConstraint,
                case let .valueArray(valueArray) = valueConstraint,
                let popUpButtonMenuItemIndex = object as? Int {
                item = try! valueArray[popUpButtonMenuItemIndex].value.propertyListItem()
            } else {
                // Otherwise, just create a property list item
                item = try! propertyListObject.propertyListItem()
            }

            setValue(item, of: treeNode)
        default:
            preconditionFailure("Unknown table column")
        }
    }


    // MARK: - Outline View Delegate

    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        guard let tableColumn = tableColumn else {
            return nil
        }

        let treeNode = item as! PropertyListTreeNode
        let tableColumnIdentifier = tableColumn.identifier

        switch tableColumnIdentifier {
        case .valueColumn:
            return valueCell(for: treeNode)
        case .keyColumn, .typeColumn:
            return tableColumn.dataCell as? NSCell
        default:
            preconditionFailure("Unknown table column")
        }
    }


    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
        let treeNode = item as! PropertyListTreeNode
        let tableColumn = tableColumn!.identifier

        switch tableColumn {
        case .keyColumn:
            return treeNode.parent?.item.propertyListType == .dictionary
        case .typeColumn:
            return true
        case .valueColumn:
            return !treeNode.item.isCollection
        default:
            preconditionFailure("Unknown table column")
        }
    }


    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        // This method will return true unless the edit happened in the Key column and the row’s
        // parent item (a dictionary) already contains the key that the user typed in

        // If there was no edited row, column, or there was no string that was typed in,
        // return true. (This should never happen, but the compiler doesn’t know that)
        let editedRow = propertyListOutlineView.editedRow
        let editedColumn = propertyListOutlineView.editedColumn
        guard editedRow != -1 && editedColumn != -1 else {
            return true
        }
        
        // If the column that was being edited wasn’t the Key column, return true
        let tableColumnIdentifier = propertyListOutlineView.tableColumns[editedColumn].identifier
        if tableColumnIdentifier == .keyColumn {
            return true
        }

        // parent should never be nil, since we only allow the Key column to be edited
        // if the parent of the row’s item is a dictionary
        let treeNode = propertyListOutlineView.item(atRow: editedRow) as! PropertyListTreeNode
        let parent = treeNode.parent!

        // If we’re a dictionary item (we definitely are), only let the edit end if the key is
        // not already in the dictionary.
        switch parent.item {
        case let .dictionary(dictionary):
            return !dictionary.containsKey(fieldEditor.string)
        default:
            return true
        }
    }


    private func valueCell(for treeNode: PropertyListTreeNode) -> NSCell {
        let item = treeNode.item
        let tableColumn = propertyListOutlineView.tableColumn(withIdentifier: .keyColumn)!

        // If we’re a collection, just use a copy of the prototype cell with the disabled text color
        if item.isCollection {
            let cell = (tableColumn.dataCell as! NSCopying).copy() as! NSTextFieldCell
            cell.textColor = NSColor.disabledControlTextColor
            return cell
        }

        // If we don’t have a value constraint, just use the normal text cell
        guard let valueConstraint = item.valueConstraint else {
            return tableColumn.dataCell as! NSTextFieldCell
        }

        switch valueConstraint {
        case let .formatter(formatter):
            // If our value constraint is a formatter, make a copy of the prototype cell and add the
            // formatter to it.
            let cell = (tableColumn.dataCell as! NSCopying).copy() as! NSTextFieldCell
            cell.formatter = formatter
            return cell
        case let .valueArray(validValues):
            // Otherwise, generate a pop-up button with the array of valid values
            return popUpButtonCell(withValidValues: validValues)
        }
    }


    private func popUpButtonCell(withValidValues validValues: [PropertyListValidValue]) -> NSPopUpButtonCell {
        let cell = NSPopUpButtonCell()
        cell.isBordered = false
        cell.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .small))

        for validValue in validValues {
            cell.addItem(withTitle: validValue.localizedDescription)
            cell.menu!.items.last!.representedObject = validValue.value
        }

        return cell
    }


    // MARK: - UI Validation

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        let selectors: Set<Selector> = [#selector(PropertyListDocument.addChild(_:)),
                                        #selector(PropertyListDocument.addSibling(_:)),
                                        #selector(PropertyListDocument.deleteItem(_:))]
        guard let action = item.action, selectors.contains(action) else {
            return super.validateUserInterfaceItem(item)
        }

        let treeNode: PropertyListTreeNode
        if propertyListOutlineView.numberOfSelectedRows == 0 {
            treeNode = tree.rootNode
        } else {
            treeNode = propertyListOutlineView.item(atRow: propertyListOutlineView.selectedRow) as! PropertyListTreeNode
        }

        switch action {
        case #selector(PropertyListDocument.addChild(_:)):
            return treeNode.item.isCollection
        case #selector(PropertyListDocument.addSibling(_:)), #selector(PropertyListDocument.deleteItem(_:)):
            return !treeNode.isRootNode
        default:
            return false
        }
    }


    // MARK: - Action Methods

    @IBAction func addChild(_ sender: AnyObject?) {
        var rowIndex = propertyListOutlineView.selectedRow
        if rowIndex == -1 {
            rowIndex = 0
        }

        let treeNode = propertyListOutlineView.item(atRow: rowIndex) as! PropertyListTreeNode
        guard treeNode.isExpandable else {
            NSLog("Received addChild: on unexpandable item. Ignoring…")
            return
        }

        insert(itemForAdding(), at: treeNode.numberOfChildren, in: treeNode)
        editTreeNode(treeNode.lastChild!)
    }


    @IBAction func addSibling(_ sender: AnyObject?) {
        let selectedRow = propertyListOutlineView.selectedRow

        guard selectedRow != -1,
            let selectedNode = propertyListOutlineView.item(atRow: selectedRow) as? PropertyListTreeNode,
            let parent = selectedNode.parent,
            parent.item.isCollection else {
                return
        }

        let index: Int! = selectedNode.index
        insert(itemForAdding(), at: index + 1, in: parent)
        editTreeNode(parent.child(at: index + 1))
    }


    @IBAction func deleteItem(_ sender: AnyObject?) {
        let selectedRow = propertyListOutlineView.selectedRow

        guard selectedRow != -1,
            let selectedNode = propertyListOutlineView.item(atRow: selectedRow) as? PropertyListTreeNode,
            let parentNode = selectedNode.parent,
            parentNode.item.isCollection else {
                return
        }

        // Abort any current edits before deleting the row, else we’ll get a crash.
        if propertyListOutlineView.editedRow != -1 {
            propertyListOutlineView.abortEditing()
        }

        let index: Int! = selectedNode.index
        remove(at: index, in: parentNode)
    }


    private func editTreeNode(_ treeNode: PropertyListTreeNode) {
        let rowIndex = propertyListOutlineView.row(forItem: treeNode)

        let columnIdentifier: NSUserInterfaceItemIdentifier
        if treeNode.isRootNode {
            columnIdentifier = .valueColumn
        } else {
            columnIdentifier = treeNode.parent!.item.propertyListType == .dictionary ? .keyColumn : .valueColumn
        }

        let columnIndex = propertyListOutlineView.tableColumns.firstIndex(where: { $0.identifier == columnIdentifier })!
        propertyListOutlineView.selectRowIndexes(IndexSet(integer: rowIndex), byExtendingSelection: false)
        propertyListOutlineView.editColumn(columnIndex, row: rowIndex, with: nil, select: true)

    }


    // MARK: - Accessing Tree Node Item Data

    /// Returns the string to display in the Key column for the specified tree node.
    /// - parameter treeNode: The tree node whose key is being returned.
    private func key(of treeNode: PropertyListTreeNode) -> NSString {
        guard let index = treeNode.index else {
            return NSLocalizedString("PropertyListDocument.RootNodeKey", comment: "Key for root node") as NSString
        }

        // Parent node will be non-nil if index is non-nil
        switch treeNode.parent!.item {
        case .array:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayItemKeyFormat", comment: "Format string for array item node key")
            return NSString.localizedStringWithFormat(formatString as NSString, index)
        case let .dictionary(dictionary):
            return dictionary[index].key as NSString
        default:
            fatalError("Impossible state: all nodes must be the root node or the child of a dictionary/array")
        }
    }


    /// Sets the key for the specified tree node. Due to the implementation of other data source
    /// methods, the tree node can be assumed to have a dictionary item as its parent.
    ///
    /// This method works by getting the parent of the specified tree node, getting its
    /// (dictionary) item, and editing it by replacing the tree node’s corresponding key with
    /// the new key. The parent node’s (dictionary) item is then replaced with the edited
    /// version using `setItem(_:ofTreeNodeAt:nodeOperation:)`. That method handles
    /// making actual model changes and registering an appropriate undo action.
    ///
    /// - parameter key: The key being set. If the dictionary already contains this key, has no
    ///       effect. This should not be possible because of our implementation of
    //        `control(_:textShouldEndEditing:)`.
    /// - parameter treeNode: The tree node whose key is being set.
    private func setKey(_ key: String, of treeNode: PropertyListTreeNode) {
        guard let parent = treeNode.parent, let index = treeNode.index else {
            return
        }

        if case var .dictionary(dictionary) = parent.item {
            guard !dictionary.containsKey(key) else {
                return
            }

            dictionary.setKey(key, at: index)
            setItem(.dictionary(dictionary), ofTreeNodeAt: parent.indexPath)
        }
    }


    /// Returns the index corresponding to the tree node’s type in the type pop-up menu.
    /// - parameter treeNode: The tree node whose type pop-up menu index is being returned.
    private func typePopUpMenuItemIndex(of treeNode: PropertyListTreeNode) -> Int {
        return treeNode.item.propertyListType.typePopUpMenuItemIndex
    }


    /// Sets the type for the specified tree node.
    ///
    /// This method works by first converting the existing property list item of the tree node
    /// to the new type and then invoking `setValue(_:of:needsChildRegeneration:)` with the
    /// new value. Child regeneration is needed when the type of the given tree goes from
    /// being a scalar to a collection or vice versa.
    ///
    /// - parameter type: The type being set.
    /// - parameter treeNode: The tree node whose type is being set.
    private func setType(_ type: PropertyListType, of treeNode: PropertyListTreeNode) {
        let wasCollection = treeNode.item.isCollection
        let newValue = treeNode.item.converting(to: type)
        let isCollection = newValue.isCollection

        // We only need child regeneration if we changed from being a scalar to a collection or
        // vice versa.  If we changed types from one collection to another, we keep our children
        // as part of type conversion, so the node hierarchy doesn’t change at all.
        setValue(newValue, of: treeNode, needsChildRegeneration: wasCollection != isCollection)
    }


    /// Returns the object value to display in the Value column for the specified tree node.
    /// - parameter treeNode: The tree node whose object value is being returned.
    private func value(of treeNode: PropertyListTreeNode) -> Any {
        switch treeNode.item {
        case .array:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayValueFormat", comment: "Format string for values of arrays")
            return NSString.localizedStringWithFormat(formatString as NSString, treeNode.numberOfChildren)
        case .dictionary:
            let formatString = NSLocalizedString("PropertyListDocument.DictionaryValueFormat", comment: "Format string for values of dictionaries")
            return NSString.localizedStringWithFormat(formatString as NSString, treeNode.numberOfChildren)
        default:
            return treeNode.item.propertyListObjectValue
        }
    }


    /// Sets the value for the specified tree node. If the node’s parent item is not a
    /// dictionary, this simply means replacing the node’s item with the one specified. For
    /// nodes that represent a key-value pair in a dictionary, this method sets the pair’s value
    /// to the one specified.
    ///
    /// This method works by getting the parent of the specified tree node, getting its item,
    /// and editing it by replacing the tree node’s corresponding value with the new one. The
    /// parent node’s item is then replaced with the edited version using
    /// `setItem(_:ofTreeNodeAt:nodeOperation:)`. That method handles making actual model
    /// changes and registering an appropriate undo action.
    ///
    /// - parameter newValue: The value being set.
    /// - parameter treeNode: The tree node for which the value is being set.
    /// - parameter needsChildRegeneration: Whether setting the new value should result in the
    ///       node’s child nodes being regenerated. This is `false` by default. Child
    ///       regeneration is appropriate when the effect of the edit changes the property list
    ///       item hierarchy.
    private func setValue(_ newValue: PropertyListItem, of treeNode: PropertyListTreeNode, needsChildRegeneration: Bool = false) {
        guard let parent = treeNode.parent else {
            let nodeOperation: TreeNodeOperation? = needsChildRegeneration ? .regenerateChildren : nil
            setItem(newValue, ofTreeNodeAt: tree.rootNode.indexPath as IndexPath, nodeOperation: nodeOperation)
            return
        }

        // index is not nil because parent is not nil
        let index = treeNode.index!
        let item: PropertyListItem

        switch parent.item {
        case var .array(array):
            array[index] = newValue
            item = .array(array)
        case var .dictionary(dictionary):
            dictionary.setValue(newValue, at: index)
            item = .dictionary(dictionary)
        default:
            item = newValue
        }

        let nodeOperation: TreeNodeOperation? = needsChildRegeneration ? .regenerateChildrenForChildAt(index) : nil
        setItem(item, ofTreeNodeAt: parent.indexPath as IndexPath, nodeOperation: nodeOperation)
    }


    /// Inserts the specified item as a child of `treeNode`’s item at the specified index.
    ///
    /// This method works by replacing `treeNode`’s item with an edited version that has the new
    /// item added to it. It then invokes `setItem(_:ofTreeNodeAt:nodeOperation:)`, which
    /// handles making actual model changes and registering an appropriate undo action.
    ///
    /// - parameter item: The item being added.
    /// - parameter index: The index in `treeNode`’s item at which to add the new item.
    /// - parameter treeNode: The tree node that is having a child added to it. Raises an
    ///       assertion if `treeNode`’s item is not a collection.
    private func insert(_ item: PropertyListItem, at index: Int, in treeNode: PropertyListTreeNode) {
        let newItem: PropertyListItem

        switch treeNode.item {
        case var .array(array):
            array.insert(item, at: index)
            newItem = .array(array)
        case var .dictionary(dictionary):
            dictionary.insertKey(dictionary.unusedKey(), value: item, at: index)
            newItem = .dictionary(dictionary)
        default:
            fatalError("Attempt to insert child at index \(index) in scalar tree node \(treeNode)")
        }

        setItem(newItem, ofTreeNodeAt: treeNode.indexPath as IndexPath, nodeOperation: .insertChildAt(index))
    }


    /// Removes the child item at the specified index from `treeNode`’s item.
    ///
    /// This method works by replacing `treeNode`’s item with an edited version that removes the
    /// child item at the specified index. It then invokes
    /// `setItem(_:ofTreeNodeAt:nodeOperation:)`, which handles making actual model
    /// changes and registering an appropriate undo action.
    ///
    /// - parameter index: The index of the child to remove in `treeNode`’s item.
    /// - parameter treeNode: The tree node that is having a child removed from it. Raises an
    ///       assertion if `treeNode`’s item is not a collection.
    private func remove(at index: Int, in treeNode: PropertyListTreeNode) {
        let newItem: PropertyListItem

        switch treeNode.item {
        case var .array(array):
            array.remove(at: index)
            newItem = .array(array)
        case var .dictionary(dictionary):
            dictionary.remove(at: index)
            newItem = .dictionary(dictionary)
        default:
            fatalError("Attempt to remove child at index \(index) in scalar tree node \(treeNode)")
        }

        setItem(newItem, ofTreeNodeAt: treeNode.indexPath as IndexPath, nodeOperation: .removeChildAt(index))
    }


    /// Sets the item of the tree node at the specified index path to the one specified and then
    /// performs the specified tree node operation.
    ///
    /// This method also registers an appropriate undo operation that sets the item of the tree
    /// node back to the original value and undoes the node operation.
    ///
    /// This is the only method in this class that makes direct changes to instance’s backing
    /// data model. All other methods ultimately funnel through this method. This is primarily to
    /// make undo/redo easier to reason about.
    ///
    /// - parameter newItem: The new item that is being set.
    /// - parameter indexPath: The index path of the tree node whose item is being set. This is
    ///       used instead of the tree node itself because an undo/redo operation might occur on
    ///       a different tree node than the one that was in the tree at the time of the original
    ///       edit.
    /// - parameter nodeOperation: An optional tree node operation to perform to keep the tree node
    ///       hierarchy in sync with the property list item hierarchy. `nil` by default. If this
    ///       is non-`nil` and not `.RemoveChildAtIndex(index)`, the tree node that was inserted
    ///       or had children regenerated for it will be expanded.
    private func setItem(_ newItem: PropertyListItem, ofTreeNodeAt indexPath: IndexPath, nodeOperation: TreeNodeOperation? = nil) {
        let treeNode = tree.node(at: indexPath)
        let oldItem = treeNode.item

        undoManager!.registerUndo(withTarget: self) { target in
            target.setItem(oldItem, ofTreeNodeAt: indexPath, nodeOperation: nodeOperation?.inverseOperation)
        }

        treeNode.item = newItem
        nodeOperation?.performOperation(on: treeNode)

        propertyListOutlineView.reloadItem(treeNode, reloadChildren: true)

        if let nodeOperation = nodeOperation {
            switch nodeOperation {
            case let .insertChildAt(index):
                propertyListOutlineView.expandItem(treeNode.child(at: index))
            case let .regenerateChildrenForChildAt(index):
                propertyListOutlineView.expandItem(treeNode.child(at: index))
            case .regenerateChildren:
                propertyListOutlineView.expandItem(treeNode)
            default:
                break
            }
        }
    }


    /// Returns the default item to add to our backing property list when a new row is added to
    /// the outline view.
    private func itemForAdding() -> PropertyListItem {
        return PropertyListItem(propertyListType: .string)
    }
}


// MARK: - Nibs

private extension NSNib.Name {
    static let propertyListDocument = "PropertyListDocument"
}


// MARK: - Table Column Identifiers

private extension NSUserInterfaceItemIdentifier {
    static let keyColumn = NSUserInterfaceItemIdentifier("key")
    static let typeColumn = NSUserInterfaceItemIdentifier("type")
    static let valueColumn = NSUserInterfaceItemIdentifier("value")
}


// MARK: - Value Constraints

/// `PropertyListValueConstraints` represent constraints for valid values on property list items. A
/// value constraint can take one of two forms: a formatter that should be used to convert to and
/// from a string representation of the value; and an array of valid values that represent all the
/// values the item can have.
private enum PropertyListValueConstraint {
    /// Represents a formatter value constraint.
    case formatter(Foundation.Formatter)

    /// Represents an array of valid values.
    case valueArray([PropertyListValidValue])
}


/// `PropertyListValidValues` represent the valid values that a property list item can have.
private struct PropertyListValidValue {
    /// An object representation of the value.
    let value: PropertyListItemConvertible

    /// A localized, user-presentable description of the value.
    let localizedDescription: String
}


private extension PropertyListItem {
    /// Returns an value constraint for the property list item type or `nil` if there are
    /// no constraints for the item.
    var valueConstraint: PropertyListValueConstraint? {
        switch self {
        case .boolean:
            let falseTitle = NSLocalizedString("PropertyListValue.Boolean.FalseTitle", comment: "Title for Boolean false value")
            let falseValidValue = PropertyListValidValue(value: NSNumber(value: false), localizedDescription: falseTitle)
            let trueTitle = NSLocalizedString("PropertyListValue.Boolean.TrueTitle", comment: "Title for Boolean true value")
            let trueValidValue = PropertyListValidValue(value: NSNumber(value: true), localizedDescription: trueTitle)
            return .valueArray([falseValidValue, trueValidValue])
        case .data:
            return .formatter(PropertyListDataFormatter())
        case .date:
            struct SharedFormatter {
                static let dateFormatter = LenientDateFormatter()
            }

            return .formatter(SharedFormatter.dateFormatter)
        case .number:
            return .formatter(NumberFormatter.propertyList)
        default:
            return nil
        }
    }
}


// MARK: - Tree Node Operations

/// The `TreeNodeOperation` enum enumerates the different operations that can be taken on a tree
/// node. Because all operations on a property list item ultimately boils down to replacing an item
/// with a new one, we need some way to discern what corresponding node operation needs to take
/// place. That’s what `TreeNodeOperations` are for.
private enum TreeNodeOperation {
    /// Indicates that a child node should be inserted at the specified index.
    case insertChildAt(Int)

    /// Indicates that the child node at the specified index should be removed.
    case removeChildAt(Int)

    /// Indicates that the child node at the specified index should have its children regenerated.
    case regenerateChildrenForChildAt(Int)

    /// Indicates that the node should regenerate its children.
    case regenerateChildren


    /// Returns the inverse of the specified operation. This is useful when undoing an operation.
    var inverseOperation: TreeNodeOperation {
        switch self {
        case let .insertChildAt(index):
            return .removeChildAt(index)
        case let .removeChildAt(index):
            return .insertChildAt(index)
        case .regenerateChildrenForChildAt, .regenerateChildren:
            return self
        }
    }


    /// Performs the instance’s operation on the specified tree node.
    /// - parameter treeNode: The tree node on which to perform the operation.
    func performOperation(on treeNode: PropertyListTreeNode) {
        switch self {
        case let .insertChildAt(index):
            treeNode.insertChild(at: index)
        case let .removeChildAt(index):
            treeNode.removeChild(at: index)
        case let .regenerateChildrenForChildAt(index):
            treeNode.child(at: index).regenerateChildren()
        case .regenerateChildren:
            treeNode.regenerateChildren()
        }
    }
}


// MARK: - Generating Unused Dictionary Keys

private extension PropertyListDictionary {
    /// Returns a key that the instance does not contain.
    func unusedKey() -> String {
        let formatString = NSLocalizedString("PropertyListDocument.KeyForAddingFormat",
                                             comment: "Format string for key generated when adding a dictionary item")

        var key: String
        var counter: Int = 1
        repeat {
            key = NSString.localizedStringWithFormat(formatString as NSString, counter) as String
            counter += 1
        } while containsKey(key)

        return key
    }
}


// MARK: - Converting Between Property List Types

private extension PropertyListItem {
    /// Returns a default property list item of the specified type.
    /// - parameter type: The property list type of the new item.
    init(propertyListType: PropertyListType) {
        switch propertyListType {
        case .array:
            self = .array(PropertyListArray())
        case .boolean:
            self = .boolean(false)
        case .data:
            self = .data(Data() as NSData)
        case .date:
            self = .date(Date() as NSDate)
        case .dictionary:
            self = .dictionary(PropertyListDictionary())
        case .number:
            self = .number(NSNumber(value: 0))
        case .string:
            let string = NSLocalizedString("PropertyListDocument.ItemForAddingStringValue", comment: "Default value when adding a new item")
            self = .string(string as NSString)
        }
    }


    /// Returns a new property list item by converting the instance to the specified type.
    /// - parameter type: The type of property list item to convert the instance to.
    func converting(to type: PropertyListType) -> PropertyListItem {
        if propertyListType == type {
            return self
        }

        let defaultItem = PropertyListItem(propertyListType: type)

        switch self {
        case let .array(array):
            if type == .dictionary {
                var dictionary = PropertyListDictionary()

                for element in array.elements {
                    dictionary.addKey(dictionary.unusedKey(), value: element)
                }

                return .dictionary(dictionary)
            }

            return defaultItem
        case let .boolean(boolean):
            switch type {
            case .number:
                return .number(boolean.boolValue ? 1 : 0)
            case .string:
                return .string(description as NSString)
            default:
                return defaultItem
            }
        case let .date(date):
            return type == .number ? .number(date.timeIntervalSince1970 as NSNumber) : defaultItem
        case let .dictionary(dictionary):
            if type == .array {
                var array = PropertyListArray()

                for element in dictionary.elements {
                    array.append(element.value)
                }

                return .array(array)
            }

            return defaultItem
        case let .number(number):
            switch type {
            case .boolean:
                return .boolean(number.boolValue as NSNumber)
            case .date:
                return .date(Date(timeIntervalSince1970: number.doubleValue) as NSDate)
            case .string:
                return .string(number.description as NSString)
            default:
                return defaultItem
            }
        case let .string(string):
            switch type {
            case .boolean:
                return .boolean((string.caseInsensitiveCompare("YES") == .orderedSame || string.caseInsensitiveCompare("true") == .orderedSame) as NSNumber)
            case .data:
                if let data = PropertyListDataFormatter().data(from: string as String) {
                    return .data(data as NSData)
                }

                return defaultItem
            case .date:
                if let date = LenientDateFormatter().date(from: string as String) {
                    return .date(date as NSDate)
                }

                return defaultItem
            case .number:
                if let number = NumberFormatter.propertyList.number(from: string as String) {
                    return .number(number)
                }

                return defaultItem
            default:
                return defaultItem
            }
        default:
            return defaultItem
        }
    }
}


// MARK: - Property List Type Pop-Up Menu

private extension PropertyListType {
    /// Returns the `PropertyListType` instance that corresponds to the specified index of the
    /// type pop-up menu, or `nil` if the index doesn’t have a known type correspondence.
    /// - parameter index: The index of the type pop-up menu whose type is being returned.
    init?(typePopUpMenuItemIndex index: Int) {
        switch index {
        case 0:
            self = .array
        case 1:
            self = .dictionary
        case 3:
            self = .boolean
        case 4:
            self = .data
        case 5:
            self = .date
        case 6:
            self = .number
        case 7:
            self = .string
        default:
            return nil
        }
    }
    
    
    /// Returns the index of the type pop-up menu that the instance corresponds to.
    var typePopUpMenuItemIndex: Int {
        switch self {
        case .array:
            return 0
        case .dictionary:
            return 1
        case .boolean:
            return 3
        case .data:
            return 4
        case .date:
            return 5
        case .number:
            return 6
        case .string:
            return 7
        }
    }
}
