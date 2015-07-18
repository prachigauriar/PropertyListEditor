//
//  PropertyListDocument.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/1/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class PropertyListDocument: NSDocument, NSOutlineViewDataSource {
    private enum TableColumn: String {
        case Key, Type, Value
    }


    @IBOutlet weak var propertyListOutlineView: NSOutlineView!
    @IBOutlet weak var keyTextFieldPrototypeCell: NSTextFieldCell!
    @IBOutlet weak var typePopUpButtonPrototypeCell: NSPopUpButtonCell!
    @IBOutlet weak var valueTextFieldPrototypeCell: NSTextFieldCell!


    override var windowNibName: String? {
        return "PropertyListDocument"
    }


    private var rootNode: PropertyListRootNode! {
        didSet {
            self.propertyListOutlineView?.reloadData()
        }
    }


    override init() {
        super.init()
        let emptyDictionaryItem = PropertyListItem.DictionaryNode(PropertyListDictionaryNode())
        self.rootNode = PropertyListRootNode(item: emptyDictionaryItem)
    }


    // MARK: - NSDocument Methods

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
    }


    override func dataOfType(typeName: String) throws -> NSData {
        return self.rootNode.XMLData()
    }


    override func readFromData(data: NSData, ofType typeName: String) throws {
        var format: NSPropertyListFormat = .XMLFormat_v1_0
        let propertyList = try NSPropertyListSerialization.propertyListWithData(data, options: [], format: &format)

        do {
            self.rootNode = try PropertyListRootNode(propertyListObject: propertyList as! PropertyListItemConvertible)
        } catch let error {
            print("Error reading document: \(error)")
            throw error
        }
    }


    // MARK: - Action Methods

    @IBAction func addChild(sender: AnyObject?) {
        let selectedRow = self.propertyListOutlineView.selectedRow
        guard selectedRow != -1,
            let selectedItem = self.propertyListOutlineView.itemAtRow(selectedRow),
            let itemNode = selectedItem as? PropertyListItemNode else {
                return
        }

        self.insertChildNodeWithItem(self.itemForAdding(), inItemNode: itemNode, atIndex: itemNode.numberOfChildNodes)
    }


    @IBAction func addSibling(sender: AnyObject?) {
        let selectedRow = self.propertyListOutlineView.selectedRow
        guard selectedRow != -1,
            let selectedItem = self.propertyListOutlineView.itemAtRow(selectedRow),
            let parent = self.propertyListOutlineView.parentForItem(selectedItem),
            let parentNode = parent as? PropertyListItemNode else {
                return
        }

        if case .Value = parentNode.item {
            return
        }

        let index: Int! = parentNode.indexOfChildNode(selectedItem as! PropertyListItemNode)
        self.insertChildNodeWithItem(self.itemForAdding(), inItemNode: parentNode, atIndex: index + 1)
        self.propertyListOutlineView.reloadItem(parent, reloadChildren: true)
    }


    @IBAction func deleteItem(sender: AnyObject?) {
        let selectedRow = self.propertyListOutlineView.selectedRow
        guard selectedRow != -1,
            let selectedItem = self.propertyListOutlineView.itemAtRow(selectedRow),
            let parent = self.propertyListOutlineView.parentForItem(selectedItem),
            let parentNode = parent as? PropertyListItemNode else {
                return
        }

        if case .Value = parentNode.item {
            return
        }


        let index: Int! = parentNode.indexOfChildNode(selectedItem as! PropertyListItemNode)
        self.removeChildNodeAtIndex(index, fromItemNode: parentNode)
        self.propertyListOutlineView.reloadItem(parent, reloadChildren: true)
    }


    private func insertChildNodeWithItem(item: PropertyListItem, inItemNode itemNode: PropertyListItemNode, atIndex index: Int) {
        switch itemNode.item {
        case let .ArrayNode(arrayNode):
            arrayNode.insertChildNodeWithItem(item, atIndex: index)
        case let .DictionaryNode(dictionaryNode):
            dictionaryNode.insertChildNodeWithKey(self.keyForAddingItemToDictionaryNode(dictionaryNode), item: item, atIndex: index)
        default:
            return
        }

        let index = itemNode.numberOfChildNodes - 1
        self.undoManager!.registerUndoWithHandler { [unowned self] in
            self.removeChildNodeAtIndex(index, fromItemNode: itemNode)
        }.setActionName("Add Node")

        self.propertyListOutlineView.reloadItem(itemNode, reloadChildren: true)
    }


    private func removeChildNodeAtIndex(index: Int, fromItemNode itemNode: PropertyListItemNode) {
        let item = itemNode.childNodeAtIndex(index).item

        switch itemNode.item {
        case let .ArrayNode(arrayNode):
            arrayNode.removeChildNodeAtIndex(index)
        case let .DictionaryNode(dictionaryNode):
            dictionaryNode.removeChildNodeAtIndex(index)
        default:
            return
        }

        self.undoManager!.registerUndoWithHandler { [unowned self] in
            self.insertChildNodeWithItem(item, inItemNode: itemNode, atIndex: index)
        }.setActionName("Delete Item")

        self.propertyListOutlineView.reloadItem(itemNode, reloadChildren: true)
    }


    // MARK: - UI Validation

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        return self.validateAction(menuItem.action, superclassInvocation: super.validateMenuItem(menuItem))
    }


    override func validateToolbarItem(toolbarItem: NSToolbarItem) -> Bool {
        return self.validateAction(toolbarItem.action, superclassInvocation: super.validateToolbarItem(toolbarItem))
    }


    private func validateAction(action: Selector, @autoclosure superclassInvocation: Void -> Bool) -> Bool {
        let selectors = Set<Selector>(arrayLiteral: "addChild:", "addSibling:", "deleteItem:")
        if !selectors.contains(action) {
            return superclassInvocation()
        }

        let outlineView = self.propertyListOutlineView
        guard outlineView.numberOfSelectedRows > 0, let itemNode = outlineView.itemAtRow(outlineView.selectedRow) as? PropertyListItemNode else {
            return false
        }

        switch action {
        case "addChild:":
            if case .Value = itemNode.item {
                return false
            } else {
                return true
            }
        case "addSibling:", "deleteItem:":
            return !(itemNode is PropertyListRootNode)
        default:
            return false
        }
    }


    // MARK: - Keys and Values for Adding Items

    private func keyForAddingItemToDictionaryNode(dictionaryNode: PropertyListDictionaryNode) -> String {
        let formatString = NSLocalizedString("PropertyListDocument.KeyForAddingFormat",
                                             comment: "Format string for key generated when adding a dictionary item")

        var key: String
        var counter: Int = 1
        repeat {
            key = NSString.localizedStringWithFormat(formatString, counter++) as String
        } while dictionaryNode.containsChildNodeWithKey(key)

        return key
    }


    private func itemForAdding() -> PropertyListItem {
        return try! NSLocalizedString("PropertyListDocument.ItemForAddingStringValue",
                                      comment: "Default value when adding a new item").propertyListItem()
    }


    // MARK: - Outline View Data Source
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 1
        }

        guard let node = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return node.numberOfChildNodes
    }


    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return self.rootNode
        }

        guard let node = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return node.childNodeAtIndex(index) as AnyObject
    }


    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        guard let node = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return node.expandable
    }


    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        guard let tableColumnIdentifier = tableColumn?.identifier, itemNode = item as? PropertyListItemNode else {
            return nil
        }

        guard let tableColumn = TableColumn(rawValue: tableColumnIdentifier) else {
            assert(false, "invalid table column identifier \(tableColumnIdentifier)")
        }


        switch tableColumn {
        case .Key:
            return self.keyForItemNode(itemNode)
        case .Type:
            return itemNode.propertyListType.typePopUpMenuItemIndex
        case .Value:
            return self.valueForItemNode(itemNode)
        }
    }


    func outlineView(outlineView: NSOutlineView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) {
        guard let tableColumnIdentifier = tableColumn?.identifier, let itemNode = item as? PropertyListItemNode else {
            return
        }

        guard let tableColumn = TableColumn(rawValue: tableColumnIdentifier) else {
            assert(false, "invalid table column identifier \(tableColumnIdentifier)")
        }

        guard let propertyListObject = object as? PropertyListItemConvertible else {
            assert(false, "object value (\(object)) is not a property list object")
        }

        switch tableColumn {
        case .Key:
            if !self.setKey(object as! String, forItemNode: itemNode) {
                NSBeep()
            }
        case .Type:
            let popUpButtonMenuItemIndex = object as! Int
            let type = PropertyListType(typePopUpMenuItemIndex: popUpButtonMenuItemIndex)!
            self.setItem(type.propertyListItemWithStringValue(""), ofItemNode: itemNode)
        case .Value:
            let item: PropertyListItem

            if let popUpButtonMenuItemIndex = object as? Int,
                case let .Value(value) = itemNode.item,
                let valueConstraint = value.valueConstraint,
                case let .ValueArray(valueArray) = valueConstraint {
                    item = try! valueArray[popUpButtonMenuItemIndex].value.propertyListItem()
            } else {
                item = try! propertyListObject.propertyListItem()
            }

            self.setItem(item, ofItemNode: itemNode)
        }
    }


    func keyForItemNode(itemNode: PropertyListItemNode) -> NSString? {
        switch itemNode {
        case is PropertyListRootNode:
            return NSLocalizedString("PropertyListDocument.RootNodeKey", comment: "Key for root node")
        case let arrayNode as PropertyListArrayItemNode:
            let formatString = NSLocalizedString("PropertyListDocument.ArrayItemKeyFormat", comment: "Format string for array item node key")
            return NSString.localizedStringWithFormat(formatString, arrayNode.index)
        case let dictionaryNode as PropertyListDictionaryItemNode:
            return dictionaryNode.key
        default:
            return nil
        }
    }


    func setKey(key: String, forItemNode itemNode: PropertyListItemNode) -> Bool {
        guard let dictionaryItemNode = itemNode as? PropertyListDictionaryItemNode where !dictionaryItemNode.parent.containsChildNodeWithKey(key) else {
            return false
        }

        let oldKey = dictionaryItemNode.key
        guard oldKey != key else {
            return true
        }

        guard let index = dictionaryItemNode.parent.indexOfChildNode(dictionaryItemNode) else {
            return false
        }

        self.undoManager!.registerUndoWithHandler() { [unowned self] in
            self.setKey(oldKey, forItemNode: itemNode)
        }.setActionName("Set Key")

        dictionaryItemNode.parent.setKey(key, forChildNodeAtIndex: index)
        self.propertyListOutlineView.reloadItem(itemNode)
        return true
    }


    func setItem(item: PropertyListItem, ofItemNode itemNode: PropertyListItemNode) {
        let oldItem = itemNode.item
        self.undoManager!.registerUndoWithHandler() { [unowned self] in
            self.setItem(oldItem, ofItemNode: itemNode)
        }.setActionName("Set Value")

        itemNode.item = item
        self.propertyListOutlineView.reloadItem(itemNode, reloadChildren: true)
    }


    func valueForItemNode(itemNode: PropertyListItemNode) -> AnyObject {
        switch itemNode.item {
        case let .Value(value):
            return value.objectValue
        default:
            let formatString = NSLocalizedString("PropertyListDocument.CollectionValueFormat", comment: "Format string for values of collections")
            return NSString.localizedStringWithFormat(formatString, itemNode.numberOfChildNodes)
        }
    }


    // MARK: - Outline View Delegate

    func outlineView(outlineView: NSOutlineView, dataCellForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSCell? {
        guard let tableColumnIdentifier = tableColumn?.identifier, itemNode = item as? PropertyListItemNode else {
            return nil
        }

        guard let tableColumn = TableColumn(rawValue: tableColumnIdentifier) else {
            assert(false, "invalid table column identifier \(tableColumnIdentifier)")
        }

        switch tableColumn {
        case .Key:
            let cell = self.keyTextFieldPrototypeCell.copy() as! NSTextFieldCell
            cell.editable = (itemNode as? PropertyListDictionaryItemNode) != nil
            return cell
        case .Type:
            return self.typePopUpButtonPrototypeCell.copy() as! NSPopUpButtonCell
        case .Value:
            switch itemNode.item {
            case let .Value(value):
                return self.valueCellForPropertyListValue(value)
            default:
                let cell = self.valueTextFieldPrototypeCell.copy() as! NSTextFieldCell
                cell.textColor = NSColor.disabledControlTextColor()
                return cell
            }
        }
    }


    func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
        guard let tableColumnIdentifier = tableColumn?.identifier, itemNode = item as? PropertyListItemNode else {
            return false
        }

        guard let tableColumn = TableColumn(rawValue: tableColumnIdentifier) else {
            assert(false, "invalid table column identifier \(tableColumnIdentifier)")
        }

        switch tableColumn {
        case .Key:
            return itemNode is PropertyListDictionaryItemNode
        case .Type:
            return true
        case .Value:
            return itemNode.propertyListType != .ArrayType && itemNode.propertyListType != .DictionaryType
        }
    }


    func valueCellForPropertyListValue(value: PropertyListValue) -> NSCell {
        guard let valueConstraint = value.valueConstraint else {
            return self.valueTextFieldPrototypeCell.copy() as! NSTextFieldCell
        }

        switch valueConstraint {
        case let .Formatter(formatter):
            let cell = self.valueTextFieldPrototypeCell.copy() as! NSTextFieldCell
            cell.formatter = formatter
            return cell
        case let .ValueArray(validValues):
            return self.popUpButtonCellWithValidValues(validValues)
        }
    }


    func popUpButtonCellWithValidValues(validValues: [PropertyListValidValue]) -> NSPopUpButtonCell {
        let cell = NSPopUpButtonCell()
        cell.bordered = false
        cell.font = NSFont.systemFontOfSize(NSFont.systemFontSizeForControlSize(.SmallControlSize))

        for validValue in validValues {
            cell.addItemWithTitle(validValue.title)
            cell.menu!.itemArray.last!.representedObject = validValue.value
        }

        return cell
    }
}


// MARK: - Private PropertyListType Extensions

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


    func propertyListItemWithStringValue(stringValue: NSString) -> PropertyListItem {
        switch self {
        case .ArrayType:
            return .ArrayNode(PropertyListArrayNode())
        case .BooleanType:
            return .Value(.BooleanValue(false))
        case .DataType:
            return .Value(.DataValue(PropertyListDataFormatter().dataFromString(stringValue as String) ?? NSData()))
        case .DateType:
            return .Value(.DateValue(LenientDateFormatter().dateFromString(stringValue as String) ?? NSDate()))
        case .DictionaryType:
            return .DictionaryNode(PropertyListDictionaryNode())
        case .NumberType:
            return .Value(.NumberValue(NSNumber(double: stringValue.doubleValue)))
        case .StringType:
            return try! stringValue.propertyListItem()
        }
    }
}
