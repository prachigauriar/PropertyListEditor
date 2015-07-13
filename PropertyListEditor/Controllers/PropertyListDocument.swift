//
//  PropertyListDocument.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/1/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class PropertyListDocument: NSDocument, NSOutlineViewDataSource {
    @IBOutlet weak var propertyListOutlineView: NSOutlineView!
    var rootNode: PropertyListRootNode!


    override init() {
        super.init()
        let emptyDictionaryItem = PropertyListItem.DictionaryNode(PropertyListDictionaryNode())
        self.rootNode = PropertyListRootNode(item: emptyDictionaryItem)
    }


    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)

        self.propertyListOutlineView.reloadData()
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
         self.rootNode = try PropertyListRootNode(propertyListObject: propertyList as! PropertyListObject)
    }


    // MARK: - NSOutlineView Delegate
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return 1
        }

        guard let item = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return item.numberOfChildren
    }


    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return self.rootNode
        }

        guard let item = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return item.childAtIndex(index)
    }


    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        guard let item = item as? PropertyListNode else {
            assert(false, "item must be a PropertyListNode")
        }

        return item.expandable
    }


    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        guard let tableColumn = tableColumn, itemNode = item as? PropertyListItemNode else {
            return nil
        }

        switch tableColumn.identifier {
        case "key":
            return "Key"
        case "type":
            return "Type"
        case "value":
            switch itemNode.item {
            case let .Value(value):
                return value.description
            case .ArrayNode:
                return "Array"
            case .DictionaryNode:
                return "Dictionary"
            }
        default:
            return nil
        }
    }


//    func outlineView(outlineView: NSOutlineView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) {
//
//    }
}

