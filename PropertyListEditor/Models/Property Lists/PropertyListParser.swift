//
//  PropertyListParser.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


/// PropertyListRootNode objects represent the root node in a property list. It simply has a single property
/// list item.
class PropertyListRootNode: PropertyListItemNode {
    var item: PropertyListItem


    /// Creates a new PropertyListRootNode with the specified item.
    /// :item: The root node’s item
    init(item: PropertyListItem) {
        self.item = item
    }


    /// Creates a new PropertyListRootNode with the specified property list object.
    /// Throws if the property list object can’t be converted into a property list item.
    /// :propertyListObject: The property list object whose item representation should be the root node’s item.
    convenience init(propertyListObject: PropertyListObject) throws {
        let item = try propertyListObject.propertyListItem()
        self.init(item: item)
    }
}


enum PropertyListParserError: ErrorType, CustomStringConvertible {
    case NonStringDictionaryKey(dictionary: NSDictionary, key: AnyObject)
    case UnsupportedObjectType(AnyObject)

    var description: String {
        switch self {
        case let .NonStringDictionaryKey(dictionary: _, key: key):
            return "Non-string key \(key) in dictionary"
        case let .UnsupportedObjectType(object):
            return "Unsupported object \(object) of type (\(object.dynamicType))"
        }
    }
}


// MARK: - PropertyListObject Protocol and Extensions

protocol PropertyListObject: NSObjectProtocol {
    func propertyListItem() throws -> PropertyListItem
}


extension NSArray: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        let arrayNode = PropertyListArrayNode()

        for (i, element) in self.enumerate() {
            guard let propertyListObject = element as? PropertyListObject else {
                throw PropertyListParserError.UnsupportedObjectType(element)
            }

            let item = try propertyListObject.propertyListItem()
            let arrayItem = PropertyListArrayItemNode(index: i, item: item)
            arrayNode.children.append(arrayItem)
        }

        return .ArrayNode(arrayNode)
    }
}


extension NSData: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.DataValue(self))
    }
}


extension NSDate: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.DateValue(self))
    }
}


extension NSDictionary: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        let dictionaryNode = PropertyListDictionaryNode()

        for (key, value) in self {
            guard let stringKey = key as? String else {
                throw PropertyListParserError.NonStringDictionaryKey(dictionary: self, key: key)
            }

            guard let propertyListObject = value as? PropertyListObject else {
                throw PropertyListParserError.UnsupportedObjectType(value)
            }

            let item = try propertyListObject.propertyListItem()
            let dictionaryItem = PropertyListDictionaryItemNode(key: stringKey, item: item)
            dictionaryNode.children.append(dictionaryItem)
        }

        return .DictionaryNode(dictionaryNode)
    }
}


extension NSNumber: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        let value: PropertyListValue = NSNumber(bool: true).objCType == self.objCType ? .BooleanValue(self) : .NumberValue(self)
        return .Value(value)
    }
}


extension NSString: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.StringValue(self))
    }
}
