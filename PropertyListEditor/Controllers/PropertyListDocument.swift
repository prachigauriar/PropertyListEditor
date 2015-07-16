//
//  PropertyListDocument.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/1/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class PropertyListDocument: NSDocument, NSOutlineViewDataSource {
    enum TableColumn: String {
        case Key, Type, Value
    }


    @IBOutlet weak var propertyListOutlineView: NSOutlineView!
    @IBOutlet weak var keyTextFieldPrototypeCell: NSTextFieldCell!
    @IBOutlet weak var typePopUpButtonPrototypeCell: NSPopUpButtonCell!
    @IBOutlet weak var valueTextFieldPrototypeCell: NSTextFieldCell!

    var rootNode: PropertyListRootNode! {
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


    override class func autosavesInPlace() -> Bool {
        return true
    }


    override var windowNibName: String? {
        return "PropertyListDocument"
    }


    override func dataOfType(typeName: String) throws -> NSData {
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }


    override func readFromData(data: NSData, ofType typeName: String) throws {
        let propertyList = try NSPropertyListSerialization.propertyListWithData(data, options: [], format: nil)

        do {
            self.rootNode = try PropertyListRootNode(propertyListObject: propertyList as! PropertyListObject)
        } catch let error {
            print("Error reading document: \(error)")
            throw error
        }
    }


    // MARK: - NSOutlineView Data Source
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 1
        }

        guard let node = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return node.numberOfChildren
    }


    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return self.rootNode
        }

        guard let node = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return node.childAtIndex(index)
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
            assert(false, "Object value requested for invalid table column identifier \(tableColumnIdentifier)")
        }


        switch tableColumn {
        case .Key:
            switch itemNode {
            case is PropertyListRootNode:
                return NSLocalizedString("Root", comment: "Key for root node")
            case let arrayNode as PropertyListArrayItemNode:
                return NSString.localizedStringWithFormat(NSLocalizedString("Item %d", comment: "Format string for array item node key"), arrayNode.index)
            case let dictionaryNode as PropertyListDictionaryItemNode:
                return dictionaryNode.key
            default:
                return nil
            }
        case .Type:
            return itemNode.propertyListType.typePopUpMenuItemIndex
        case .Value:
            switch itemNode.item {
            case let .Value(value):
                return value.objectValue
            case .ArrayNode:
                return "Array"
            case .DictionaryNode:
                return "Dictionary"
            }
        }
    }


    func outlineView(outlineView: NSOutlineView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) {
        guard let tableColumnIdentifier = tableColumn?.identifier, var itemNode = item as? PropertyListItemNode else {
            return
        }

        guard let tableColumn = TableColumn(rawValue: tableColumnIdentifier) else {
            assert(false, "Object value set for invalid table column identifier \(tableColumnIdentifier)")
        }

        guard let propertyListObject = object as? PropertyListObject else {
            assert(false, "object value (\(object)) is not a property list object")
        }

        switch tableColumn {
        case .Key:
            break
        case .Type:
            if let popUpButtonMenuItemIndex = object as? Int, type = PropertyListType(typePopUpMenuItemIndex: popUpButtonMenuItemIndex) {
                itemNode.item = type.propertyListItemWithStringValue("")
            }
        case .Value:
            if let popUpButtonMenuItemIndex = object as? Int,
                case let .Value(value) = itemNode.item,
                let valueConstraint = value.valueConstraint,
                case let .ValueArray(valueArray) = valueConstraint {
                    itemNode.item = try! valueArray[popUpButtonMenuItemIndex].value.propertyListItem()
            } else {
                itemNode.item = try! propertyListObject.propertyListItem()
            }
        }

        outlineView.reloadItem(item)
    }


    // MARK: - NSOutlineView Delegate

    func outlineView(outlineView: NSOutlineView, dataCellForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSCell? {
        guard let tableColumnIdentifier = tableColumn?.identifier, itemNode = item as? PropertyListItemNode else {
            return nil
        }

        guard let tableColumn = TableColumn(rawValue: tableColumnIdentifier) else {
            assert(false, "Object value requested for invalid table column identifier \(tableColumnIdentifier)")
        }

        switch tableColumn {
        case .Key:
            return self.keyTextFieldPrototypeCell.copy() as! NSTextFieldCell
        case .Type:
            return self.typePopUpButtonPrototypeCell.copy() as! NSPopUpButtonCell
        case .Value:
            switch itemNode.item {
            case let .Value(value):
                return self.valueCellForPropertyListValue(value)
            case .ArrayNode, .DictionaryNode:
                let cell = self.valueTextFieldPrototypeCell.copy() as! NSTextFieldCell
                cell.editable = false
                return cell
            }
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
}


// MARK: - PropertyListType ⟺ typePopUpMenuItemIndex Conversion

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
            return .Value(.DateValue(NSDateFormatter.propertyListDateFormatter().dateFromString(stringValue as String) ?? NSDate()))
        case .DictionaryType:
            return .DictionaryNode(PropertyListDictionaryNode())
        case .NumberType:
            return .Value(.NumberValue(NSNumber(double: stringValue.doubleValue)))
        case .StringType:
            return try! stringValue.propertyListItem()
        }
    }
}
