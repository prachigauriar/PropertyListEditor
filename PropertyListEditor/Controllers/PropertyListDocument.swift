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
class PropertyListDocument: NSDocument, NSOutlineViewDataSource, NSOutlineViewDelegate {
    /// The instance’s property list tree. This is the model object that controller managers.
    private var tree: PropertyListTree! {
        didSet {
            self.propertyListOutlineView?.reloadData()
        }
    }


    /// The instance’s outline view.
    @IBOutlet weak var propertyListOutlineView: NSOutlineView!


    override init() {
        self.tree = PropertyListTree()
        super.init()
    }


    deinit {
        // Failing to unset the data source here results in a stray delegate message sent to the
        // zombie PropertyListDocument. While there may be a more correct solution, I’ve yet to find
        // it.
        self.propertyListOutlineView?.setDataSource(nil)
        self.propertyListOutlineView?.setDelegate(nil)
    }


    // MARK: - NSDocument Methods

    override var windowNibName: String? {
        return "PropertyListDocument"
    }


    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        self.propertyListOutlineView.expandItem(nil, expandChildren: true)
    }


    override func dataOfType(typeName: String) throws -> NSData {
        return self.tree.rootItem.propertyListXMLDocumentData()
    }


    override func readFromData(data: NSData, ofType typeName: String) throws {
        var format: NSPropertyListFormat = .XMLFormat_v1_0
        let propertyListObject = try NSPropertyListSerialization.propertyListWithData(data, options: [], format: &format) as! PropertyListItemConvertible

        let rootItem: PropertyListItem
            
        // If the document is in binary or ASCII format, convert the NSPropertyListSerialization
        // output into a property list item. If it’s in XML, use our custom XML reader so that our
        // dictionary keys are in the same order as the XML.
        if format != .XMLFormat_v1_0 {
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

        self.tree = PropertyListTree(rootItem: rootItem)
    }


    // MARK: - Outline View Data Source

    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 1
        }

        let treeNode = item as! PropertyListTreeNode
        return treeNode.numberOfChildren
    }


    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let treeNode = item as! PropertyListTreeNode
        return treeNode.isExpandable
    }


    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return self.tree.rootNode
        }

        let treeNode = item as! PropertyListTreeNode
        return treeNode.childAtIndex(index)
    }


    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        let treeNode = item as! PropertyListTreeNode
        let tableColumnIdentifier = TableColumnIdentifier(rawValue: tableColumn!.identifier)!

        switch tableColumnIdentifier {
        case .Key:
            return self.keyOfTreeNode(treeNode)
        case .Type:
            return self.typePopUpMenuItemIndexOfTreeNode(treeNode)
        case .Value:
            return self.valueOfTreeNode(treeNode)
        }
    }


    func outlineView(outlineView: NSOutlineView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) {
        let treeNode = item as! PropertyListTreeNode
        let tableColumnIdentifier = TableColumnIdentifier(rawValue: tableColumn!.identifier)!
        let propertyListObject = object as! PropertyListItemConvertible

        switch tableColumnIdentifier {
        case .Key:
            self.setKey(object as! String, ofTreeNode: treeNode)
        case .Type:
            let type = PropertyListType(typePopUpMenuItemIndex: object as! Int)!
            self.setType(type, ofTreeNode: treeNode)
        case .Value:
            let item: PropertyListItem

            // The two cases here are the value being set by a pop-up button or the value being returned directly
            if case let nodeItem = treeNode.item,
                let valueConstraint = nodeItem.valueConstraint,
                case let .ValueArray(valueArray) = valueConstraint,
                let popUpButtonMenuItemIndex = object as? Int {
                    item = try! valueArray[popUpButtonMenuItemIndex].value.propertyListItem()
            } else {
                // Otherwise, just create a property list item
                item = try! propertyListObject.propertyListItem()
            }

            self.setValue(item, ofTreeNode: treeNode)
        }
    }


    // MARK: - Outline View Delegate

    func outlineView(outlineView: NSOutlineView, dataCellForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSCell? {
        guard let tableColumn = tableColumn else {
            return nil
        }

        let treeNode = item as! PropertyListTreeNode
        let tableColumnIdentifier = TableColumnIdentifier(rawValue: tableColumn.identifier)!

        switch tableColumnIdentifier {
        case .Value:
            return self.valueCellForTreeNode(treeNode)
        default:
            return tableColumn.dataCell as? NSCell
        }
    }


    func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
        let treeNode = item as! PropertyListTreeNode
        let tableColumn = TableColumnIdentifier(rawValue: tableColumn!.identifier)!

        switch tableColumn {
        case .Key:
            return treeNode.parentNode?.item.propertyListType == .DictionaryType
        case .Type:
            return true
        case .Value:
            return !treeNode.item.isCollection
        }
    }


    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        // This method will return true unless the edit happened in the Key column and the row’s
        // parent item (a dictionary) already contains the key that the user typed in

        // If there was no edited row, column, or there was no string that was typed in, 
        // return true. (This should never happen, but the compiler doesn’t know that)
        let editedRow = self.propertyListOutlineView.editedRow
        let editedColumn = self.propertyListOutlineView.editedColumn
        guard editedRow != -1 && editedColumn != -1, let newString = fieldEditor.string else {
            return true
        }

        // If the column that was being edited wasn’t the Key column, return true
        let tableColumn = self.propertyListOutlineView.tableColumns[editedColumn]
        guard TableColumnIdentifier(rawValue: tableColumn.identifier) == .Key else {
            return true
        }

        // parentNode should never be nil, since we only allow the Key column to be edited
        // if the parent of the row’s item is a dictionary
        let treeNode = self.propertyListOutlineView.itemAtRow(editedRow) as! PropertyListTreeNode
        let parentNode = treeNode.parentNode!

        // If we’re a dictionary item (we definitely are), only let the edit end if the key is
        // not already in the dictionary.
        switch parentNode.item {
        case let .DictionaryItem(dictionary):
            return !dictionary.containsKey(newString)
        default:
            return true
        }
    }


    private func valueCellForTreeNode(treeNode: PropertyListTreeNode) -> NSCell {
        let item = treeNode.item
        let tableColumn = self.propertyListOutlineView.tableColumnWithIdentifier(TableColumnIdentifier.Key.rawValue)!

        // If we’re a collection, just use a copy of the prototype cell with the disabled text color
        if item.isCollection {
            let cell = tableColumn.dataCell.copy() as! NSTextFieldCell
            cell.textColor = NSColor.disabledControlTextColor()
            return cell
        }

        // If we don’t have a value constraint, just use the normal text cell
        guard let valueConstraint = item.valueConstraint else {
            return tableColumn.dataCell as! NSTextFieldCell
        }

        switch valueConstraint {
        case let .Formatter(formatter):
            // If our value constraint is a formatter, make a copy of the prototype cell and add the
            // formatter to it.
            let cell = tableColumn.dataCell.copy() as! NSTextFieldCell
            cell.formatter = formatter
            return cell
        case let .ValueArray(validValues):
            // Otherwise, generate a pop-up button with the array of valid values
            return self.popUpButtonCellWithValidValues(validValues)
        }
    }


    private func popUpButtonCellWithValidValues(validValues: [PropertyListValidValue]) -> NSPopUpButtonCell {
        let cell = NSPopUpButtonCell()
        cell.bordered = false
        cell.font = NSFont.systemFontOfSize(NSFont.systemFontSizeForControlSize(.SmallControlSize))
        
        for validValue in validValues {
            cell.addItemWithTitle(validValue.localizedDescription)
            cell.menu!.itemArray.last!.representedObject = validValue.value
        }
        
        return cell
    }


    // MARK: - UI Validation

    override func validateUserInterfaceItem(userInterfaceItem: NSValidatedUserInterfaceItem) -> Bool {
        let selectors: Set<Selector> = ["addChild:", "addSibling:", "deleteItem:"]
        let action = userInterfaceItem.action()

        guard selectors.contains(action) else {
            return super.validateUserInterfaceItem(userInterfaceItem)
        }

        let treeNode: PropertyListTreeNode
        if self.propertyListOutlineView.numberOfSelectedRows == 0 {
            treeNode = self.tree.rootNode
        } else {
            treeNode = self.propertyListOutlineView.itemAtRow(self.propertyListOutlineView.selectedRow) as! PropertyListTreeNode
        }

        switch action {
        case "addChild:":
            return treeNode.item.isCollection
        case "addSibling:", "deleteItem:":
            return !treeNode.isRootNode
        default:
            return false
        }
    }


    // MARK: - Action Methods

    @IBAction func addChild(sender: AnyObject?) {
        var rowIndex = self.propertyListOutlineView.selectedRow
        if rowIndex == -1 {
            rowIndex = 0
        }

        let treeNode = self.propertyListOutlineView.itemAtRow(rowIndex) as! PropertyListTreeNode
        guard treeNode.isExpandable else {
            NSLog("Received addChild: on unexpandable item. Ignoring…")
            return
        }

        self.insertItem(self.itemForAdding(), atIndex: treeNode.numberOfChildren, inTreeNode: treeNode)
        self.editTreeNode(treeNode.lastChild!)
    }


    @IBAction func addSibling(sender: AnyObject?) {
        let selectedRow = self.propertyListOutlineView.selectedRow

        guard selectedRow != -1,
            let selectedNode = self.propertyListOutlineView.itemAtRow(selectedRow) as? PropertyListTreeNode,
            let parentNode = selectedNode.parentNode where parentNode.item.isCollection else {
                return
        }

        let index: Int! = selectedNode.index
        self.insertItem(self.itemForAdding(), atIndex: index + 1, inTreeNode: parentNode)
        self.editTreeNode(parentNode.childAtIndex(index + 1))
    }


    @IBAction func deleteItem(sender: AnyObject?) {
        let selectedRow = self.propertyListOutlineView.selectedRow

        guard selectedRow != -1,
            let selectedTreeNode = self.propertyListOutlineView.itemAtRow(selectedRow) as? PropertyListTreeNode,
            let parentTreeNode = selectedTreeNode.parentNode where parentTreeNode.item.isCollection else {
                return
        }

        // Abort any current edits before deleting the row, else we’ll get a crash.
        if self.propertyListOutlineView.editedRow != -1 {
            self.propertyListOutlineView.abortEditing()
        }

        let index: Int! = selectedTreeNode.index
        self.removeItemAtIndex(index, inTreeNode: parentTreeNode)
    }


    private func editTreeNode(treeNode: PropertyListTreeNode) {
        let rowIndex = self.propertyListOutlineView.rowForItem(treeNode)

        let tableColumnIdentifier: TableColumnIdentifier
        if treeNode.isRootNode {
            tableColumnIdentifier = .Value
        } else {
            tableColumnIdentifier = treeNode.parentNode!.item.propertyListType == .DictionaryType ? .Key : .Value
        }

        let columnIndex = tableColumnIdentifier.indexOfTableColumnWithIdentifierInOutlineView(self.propertyListOutlineView)!
        self.propertyListOutlineView.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: false)
        self.propertyListOutlineView.editColumn(columnIndex, row: rowIndex, withEvent: nil, select: true)

    }


    // MARK: - Accessing Tree Node Item Data

    private func keyOfTreeNode(treeNode: PropertyListTreeNode) -> NSString? {
        guard let index = treeNode.index else {
            return NSLocalizedString("PropertyListDocument.RootNodeKey", comment: "Key for root node")
        }

        // Parent node will be non-nil if index is non-nil
        switch treeNode.parentNode!.item {
        case .ArrayItem:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayItemKeyFormat", comment: "Format string for array item node key")
            return NSString.localizedStringWithFormat(formatString, index)
        case let .DictionaryItem(dictionary):
            return dictionary.elementAtIndex(index).key
        default:
            return nil
        }
    }


    private func setKey(key: String, ofTreeNode treeNode: PropertyListTreeNode) {
        guard let parentNode = treeNode.parentNode, index = treeNode.index else {
            return
        }

        if case var .DictionaryItem(dictionary) = parentNode.item {
            guard !dictionary.containsKey(key) else {
                return
            }

            dictionary.setKey(key, atIndex: index)
            self.setItem(.DictionaryItem(dictionary), ofTreeNodeAtIndexPath: parentNode.indexPath)
        }
    }


    private func typePopUpMenuItemIndexOfTreeNode(treeNode: PropertyListTreeNode) -> Int {
        return treeNode.item.propertyListType.typePopUpMenuItemIndex
    }


    private func setType(type: PropertyListType, ofTreeNode treeNode: PropertyListTreeNode) {
        let wasCollection = treeNode.item.isCollection
        let value = treeNode.item.propertyListItemByConvertingToType(type)
        let isCollection = value.isCollection

        // We only need child regeneration if we changed from being a scalar to a collection or vice
        // versa.  If we changed types from one collection to another, we convert the children
        // automatically, so we will have the right number of nodes.
        self.setValue(value, ofTreeNode: treeNode, needsChildRegeneration: wasCollection != isCollection)
    }


    private func valueOfTreeNode(treeNode: PropertyListTreeNode) -> AnyObject {
        switch treeNode.item {
        case .ArrayItem:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayValueFormat", comment: "Format string for values of arrays")
            return NSString.localizedStringWithFormat(formatString, treeNode.numberOfChildren)
        case .DictionaryItem:
            let formatString = NSLocalizedString("PropertyListDocument.DictionaryValueFormat", comment: "Format string for values of dictionaries")
            return NSString.localizedStringWithFormat(formatString, treeNode.numberOfChildren)
        default:
            return treeNode.item.propertyListObjectValue
        }
    }
    

    private func setValue(newValue: PropertyListItem, ofTreeNode treeNode: PropertyListTreeNode, needsChildRegeneration: Bool = false) {
        guard let parentNode = treeNode.parentNode else {
            let nodeOperation: TreeNodeOperation? = needsChildRegeneration ? .RegenerateChildren : nil
            self.setItem(newValue, ofTreeNodeAtIndexPath: self.tree.rootNode.indexPath, nodeOperation: nodeOperation)
            return
        }

        // index is not nil because parentNode is not nil
        let index = treeNode.index!
        let item: PropertyListItem

        switch parentNode.item {
        case var .ArrayItem(array):
            array.replaceElementAtIndex(index, withElement: newValue)
            item = .ArrayItem(array)
        case var .DictionaryItem(dictionary):
            dictionary.setValue(newValue, atIndex: index)
            item = .DictionaryItem(dictionary)
        default:
            item = newValue
        }

        let nodeOperation: TreeNodeOperation? = needsChildRegeneration ? .RegenerateChildrenForChildAtIndex(index) : nil
        self.setItem(item, ofTreeNodeAtIndexPath: parentNode.indexPath, nodeOperation: nodeOperation)
    }


    private func insertItem(item: PropertyListItem, atIndex index: Int, inTreeNode treeNode: PropertyListTreeNode) {
        let newItem: PropertyListItem

        switch treeNode.item {
        case var .ArrayItem(array):
            array.insertElement(item, atIndex: index)
            newItem = .ArrayItem(array)
        case var .DictionaryItem(dictionary):
            dictionary.insertKey(dictionary.unusedKey(), value: item, atIndex: index)
            newItem = .DictionaryItem(dictionary)
        default:
            assert(false, "Attempt to insert child at index \(index) in scalar tree node \(treeNode)")
            return
        }

        self.setItem(newItem, ofTreeNodeAtIndexPath: treeNode.indexPath, nodeOperation: .InsertChildAtIndex(index))
    }


    private func removeItemAtIndex(index: Int, inTreeNode treeNode: PropertyListTreeNode) {
        let newItem: PropertyListItem

        switch treeNode.item {
        case var .ArrayItem(array):
            array.removeElementAtIndex(index)
            newItem = .ArrayItem(array)
        case var .DictionaryItem(dictionary):
            dictionary.removeElementAtIndex(index)
            newItem = .DictionaryItem(dictionary)
        default:
            assert(false, "Attempt to remove child at index \(index) in scalar tree node \(treeNode)")
            return
        }

        self.setItem(newItem, ofTreeNodeAtIndexPath: treeNode.indexPath, nodeOperation: .RemoveChildAtIndex(index))
    }


    private func setItem(newItem: PropertyListItem, ofTreeNodeAtIndexPath indexPath: NSIndexPath, nodeOperation: TreeNodeOperation? = nil) {
        let treeNode = self.tree.nodeAtIndexPath(indexPath)
        let oldItem = treeNode.item

        self.undoManager!.registerUndoWithHandler { [unowned self] in
            self.setItem(oldItem, ofTreeNodeAtIndexPath: indexPath, nodeOperation: nodeOperation?.inverseOperation)
        }

        treeNode.item = newItem
        nodeOperation?.performOperationOnTreeNode(treeNode)

        self.propertyListOutlineView.reloadItem(treeNode, reloadChildren: true)

        if let nodeOperation = nodeOperation {
            switch nodeOperation {
            case let .InsertChildAtIndex(index):
                self.propertyListOutlineView.expandItem(treeNode.childAtIndex(index))
            case let .RegenerateChildrenForChildAtIndex(index):
                self.propertyListOutlineView.expandItem(treeNode.childAtIndex(index))
            case .RegenerateChildren:
                self.propertyListOutlineView.expandItem(treeNode)
            default:
                break
            }
        }
    }


    private func itemForAdding() -> PropertyListItem {
        return PropertyListItem(propertyListType: .StringType)
    }
}


// MARK: - Table Column Identifiers

/// The `TableColumn` enum is used to enumerate the different `NSTableColumns` that the instance’s
/// outline view has. Whenever a table column is added to the outline view, a corresponding case
/// should be added to this enum. Additionally, the table column’s identifier should be the same as
/// the case name in this enum. The value of using this approach is that the compiler ensures that
/// all table column cases are handled by the code.
private enum TableColumnIdentifier: String {
    case Key, Type, Value


    /// Returns the index of the outline view table column whose identifier matches the instance’s.
    /// - parameter outlineView: The outline view whose table column is being returned.
    func indexOfTableColumnWithIdentifierInOutlineView(outlineView: NSOutlineView) -> Int? {
        return outlineView.tableColumns.indexOf { $0.identifier == self.rawValue }
    }
}


// MARK: - Value Constraints

/// `PropertyListValueConstraints` represent constraints for valid values on property list items. A
/// value constraint can take one of two forms: a formatter that should be used to convert to and
/// from a string representation of the value; and an array of valid values that represent all the
/// values the item can have.
private enum PropertyListValueConstraint {
    /// Represents a formatter value constraint.
    case Formatter(NSFormatter)

    /// Represents an array of valid values.
    case ValueArray([PropertyListValidValue])
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
        case .BooleanItem:
            let falseTitle = NSLocalizedString("PropertyListValue.Boolean.FalseTitle", comment: "Title for Boolean false value")
            let falseValidValue = PropertyListValidValue(value: NSNumber(bool: false), localizedDescription: falseTitle)
            let trueTitle = NSLocalizedString("PropertyListValue.Boolean.TrueTitle", comment: "Title for Boolean true value")
            let trueValidValue = PropertyListValidValue(value: NSNumber(bool: true), localizedDescription: trueTitle)
            return .ValueArray([falseValidValue, trueValidValue])
        case .DataItem:
            return .Formatter(PropertyListDataFormatter())
        case .DateItem:
            struct SharedFormatter {
                static let dateFormatter = LenientDateFormatter()
            }

            return .Formatter(SharedFormatter.dateFormatter)
        case .NumberItem:
            return .Formatter(NSNumberFormatter.propertyListNumberFormatter())
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
    case InsertChildAtIndex(Int)

    /// Indicates that the child node at the specified index should be removed.
    case RemoveChildAtIndex(Int)

    /// Indicates that the child node at the specified index should have its children regenerated.
    case RegenerateChildrenForChildAtIndex(Int)

    /// Indicates that the node should regenerate its children.
    case RegenerateChildren


    /// Returns the inverse of the specified operation. This is useful when undoing an operation.
    var inverseOperation: TreeNodeOperation {
        switch self {
        case let .InsertChildAtIndex(index):
            return .RemoveChildAtIndex(index)
        case let .RemoveChildAtIndex(index):
            return .InsertChildAtIndex(index)
        case .RegenerateChildrenForChildAtIndex, .RegenerateChildren:
            return self
        }
    }


    /// Performs the instance’s operation on the specified tree node.
    /// - parameter treeNode: The tree node on which to perform the operation.
    func performOperationOnTreeNode(treeNode: PropertyListTreeNode) {
        switch self {
        case let .InsertChildAtIndex(index):
            treeNode.insertChildAtIndex(index)
        case let .RemoveChildAtIndex(index):
            treeNode.removeChildAtIndex(index)
        case let .RegenerateChildrenForChildAtIndex(index):
            treeNode.childAtIndex(index).regenerateChildren()
        case RegenerateChildren:
            treeNode.regenerateChildren()
        }
    }
}


// MARK: - Generating Unused Dictionary Keys

private extension PropertyListDictionary {
    /// Returns a key that the instance does not contain.
    private func unusedKey() -> String {
        let formatString = NSLocalizedString("PropertyListDocument.KeyForAddingFormat",
                                             comment: "Format string for key generated when adding a dictionary item")

        var key: String
        var counter: Int = 1
        repeat {
            key = NSString.localizedStringWithFormat(formatString, counter++) as String
        } while self.containsKey(key)

        return key
    }
}


// MARK: - Converting Between Property List Types

private extension PropertyListItem {
    init(propertyListType: PropertyListType) {
        switch propertyListType {
        case .ArrayType:
            self = .ArrayItem(PropertyListArray())
        case .BooleanType:
            self = .BooleanItem(false)
        case .DataType:
            self = .DataItem(NSData())
        case .DateType:
            self = .DateItem(NSDate())
        case .DictionaryType:
            self = .DictionaryItem(PropertyListDictionary())
        case .NumberType:
            self = .NumberItem(NSNumber(integer: 0))
        case .StringType:
            let string = NSLocalizedString("PropertyListDocument.ItemForAddingStringValue", comment: "Default value when adding a new item")
            self = .StringItem(string)
        }
    }


    func propertyListItemByConvertingToType(type: PropertyListType) -> PropertyListItem {
        if self.propertyListType == type {
            return self
        }

        let defaultItem = PropertyListItem(propertyListType: type)

        switch self {
        case let .ArrayItem(array):
            if type == .DictionaryType {
                var dictionary = PropertyListDictionary()

                for element in array.elements {
                    dictionary.addKey(dictionary.unusedKey(), value: element)
                }

                return .DictionaryItem(dictionary)
            }

            return defaultItem
        case let .BooleanItem(boolean):
            switch type {
            case .NumberType:
                return .NumberItem(boolean.boolValue ? 1 : 0)
            case .StringType:
                return .StringItem(self.description)
            default:
                return defaultItem
            }
        case let .DateItem(date):
            return type == .NumberType ? .NumberItem(date.timeIntervalSince1970) : defaultItem
        case let .DictionaryItem(dictionary):
            if type == .ArrayType {
                var array = PropertyListArray()

                for element in dictionary.elements {
                    array.addElement(element.value)
                }

                return .ArrayItem(array)
            }

            return defaultItem
        case let .NumberItem(number):
            switch type {
            case .BooleanType:
                return .BooleanItem(number.boolValue)
            case .DateType:
                return .DateItem(NSDate(timeIntervalSince1970: number.doubleValue))
            case .StringType:
                return .StringItem(number.description)
            default:
                return defaultItem
            }
        case let .StringItem(string):
            switch type {
            case .BooleanType:
                return .BooleanItem(string.caseInsensitiveCompare("YES") == .OrderedSame || string.caseInsensitiveCompare("true") == .OrderedSame)
            case .DataType:
                if let data = PropertyListDataFormatter().dataFromString(string as String) {
                    return .DataItem(data)
                }

                return defaultItem
            case .DateType:
                if let date = LenientDateFormatter().dateFromString(string as String) {
                    return .DateItem(date)
                }

                return defaultItem
            case .NumberType:
                if let number = NSNumberFormatter.propertyListNumberFormatter().numberFromString(string as String) {
                    return .NumberItem(number)
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
    init?(typePopUpMenuItemIndex index: Int) {
        switch index {
        case 0:
            self = .ArrayType
        case 1:
            self = .DictionaryType
        case 3:
            self = .BooleanType
        case 4:
            self = .DataType
        case 5:
            self = .DateType
        case 6:
            self = .NumberType
        case 7:
            self = .StringType
        default:
            return nil
        }
    }


    var typePopUpMenuItemIndex: Int {
        switch self {
        case .ArrayType:
            return 0
        case .DictionaryType:
            return 1
        case .BooleanType:
            return 3
        case .DataType:
            return 4
        case .DateType:
            return 5
        case .NumberType:
            return 6
        case .StringType:
            return 7
        }
    }
}
