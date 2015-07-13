//
//  PropertyListDocument.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/1/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class PropertyListDocument: NSDocument, NSOutlineViewDataSource {
    enum TypePopUpButtonTag: Int {
        case Array = 10001
        case Dictionary = 10002
        case Boolean = 10003
        case Data = 10004
        case Date = 10005
        case Number = 10006
        case String = 10007

        init(itemNode: PropertyListItemNode) {
            switch itemNode.item {
            case .ArrayNode:
                self = .Array
            case .DictionaryNode:
                self = .Dictionary
            case let .Value(value):
                switch value {
                case .BooleanValue:
                    self = .Boolean
                case .DataValue:
                    self = .Data
                case .DateValue:
                    self = .Date
                case .NumberValue:
                    self = .Number
                case .StringValue:
                    self = .String
                }
            }
        }
    }

    
    enum TableColumn: String {
        case Key
        case Type
        case Value

        init?(identifier: String) {
            switch identifier {
            case "key":
                self = .Key
            case "type":
                self = .Type
            case "value":
                self = .Value
            default:
                return nil
            }
        }
    }


    @IBOutlet weak var propertyListOutlineView: NSOutlineView!
    @IBOutlet weak var keyTextFieldCell: NSTextFieldCell!
    @IBOutlet weak var typePopUpButtonCell: NSPopUpButtonCell!

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

        guard let tableColumn = TableColumn(identifier: tableColumnIdentifier) else {
            assert(false, "Object value requested for invalid table column identifier \(tableColumnIdentifier)")
        }


        switch tableColumn {
        case .Key:
            return "Key"
        case .Type:
            return "Type"
        case .Value:
            switch itemNode.item {
            case let .Value(value):
                return value.description
            case .ArrayNode:
                return "Array"
            case .DictionaryNode:
                return "Dictionary"
            }
        }
    }


//    func outlineView(outlineView: NSOutlineView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) {
//
//    }


    // MARK: - NSOutlineView Delegate
    func outlineView(outlineView: NSOutlineView, dataCellForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSCell? {
        guard let tableColumnIdentifier = tableColumn?.identifier, itemNode = item as? PropertyListItemNode else {
            return nil
        }

        guard let tableColumn = TableColumn(identifier: tableColumnIdentifier) else {
            assert(false, "Object value requested for invalid table column identifier \(tableColumnIdentifier)")
        }

        switch tableColumn {
        case .Key:
            return self.keyTextFieldCell
        case .Type:
            self.typePopUpButtonCell.selectItemWithTag(TypePopUpButtonTag(itemNode: itemNode).rawValue)
            self.typePopUpButtonCell.synchronizeTitleAndSelectedItem()
            return self.typePopUpButtonCell
        case .Value:
            switch itemNode.item {
            case let .Value(value):
                return self.valueCellForPropertyListValue(value)
            case .ArrayNode:
                fallthrough
            case .DictionaryNode:
                return NSTextFieldCell()
            }
        }
    }


    func valueCellForPropertyListValue(value: PropertyListValue) -> NSCell {
        guard let valueConstraint = value.valueConstraint else {
            return NSTextFieldCell()
        }

        switch valueConstraint {
        case let .Formatter(formatter):
            let cell = NSTextFieldCell()
            cell.formatter = formatter
            return cell
        case let .ValueArray(validValues):
            let cell = NSPopUpButtonCell()
            cell.bordered = false

            for validValue in validValues {
                cell.addItemWithTitle(validValue.title)
                cell.menu!.itemArray.last!.representedObject = validValue.value
            }

            return cell
        }
    }
}


