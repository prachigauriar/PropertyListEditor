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


    convenience init(propertyListObject: PropertyListObject) throws {
        let item = try propertyListObject.propertyListItem()
        self.init(item: item)
    }
}


enum PropertyListParserError: ErrorType {
    case InvalidPropertyListObject
}


// MARK: - PropertyListValueObject Extensions

protocol PropertyListObject {
    func propertyListItem() throws -> PropertyListItem
}


extension Bool: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.BooleanValue(self))
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


extension NSNumber: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.NumberValue(self))
    }
}


extension String: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.StringValue(self))
    }
}


// MARK: - PropertyListCollectionObject

extension NSArray: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        let arrayNode = PropertyListArrayNode()

        for element in self {
            guard let propertyListObject = element as? PropertyListObject else {
                throw PropertyListParserError.InvalidPropertyListObject
            }

            let item = try propertyListObject.propertyListItem()
            let arrayItem = PropertyListArrayItemNode(item: item)
            arrayNode.children.append(arrayItem)
        }

        return .ArrayNode(arrayNode)
    }
}


extension NSDictionary: PropertyListObject {
    func propertyListItem() throws -> PropertyListItem {
        let dictionaryNode = PropertyListDictionaryNode()

        for (key, value) in self {
            guard let key = key as? String, propertyListObject = value as? PropertyListObject else {
                throw PropertyListParserError.InvalidPropertyListObject
            }

            let item = try propertyListObject.propertyListItem()
            let dictionaryItem = PropertyListDictionaryItemNode(key: key, item: item)
            dictionaryNode.children.append(dictionaryItem)
        }

        return .DictionaryNode(dictionaryNode)
    }
}
