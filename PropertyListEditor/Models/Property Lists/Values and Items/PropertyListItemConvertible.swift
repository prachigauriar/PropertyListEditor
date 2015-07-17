//
//  PropertyListParser.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


enum PropertyListConversionError: ErrorType, CustomStringConvertible {
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


// MARK: - PropertyListItemConvertible Protocol and Extensions

protocol PropertyListItemConvertible: NSObjectProtocol {
    func propertyListItem() throws -> PropertyListItem
}


extension NSArray: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        let arrayNode = PropertyListArrayNode()

        for element in self {
            guard let propertyListObject = element as? PropertyListItemConvertible else {
                throw PropertyListConversionError.UnsupportedObjectType(element)
            }

            arrayNode.addChildNodeWithItem(try propertyListObject.propertyListItem())
        }

        return .ArrayNode(arrayNode)
    }
}


extension NSData: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.DataValue(self))
    }
}


extension NSDate: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.DateValue(self))
    }
}


extension NSDictionary: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        let dictionaryNode = PropertyListDictionaryNode()

        for (key, value) in self {
            guard let stringKey = key as? String else {
                throw PropertyListConversionError.NonStringDictionaryKey(dictionary: self, key: key)
            }

            guard let propertyListObject = value as? PropertyListItemConvertible else {
                throw PropertyListConversionError.UnsupportedObjectType(value)
            }

            dictionaryNode.addChildNodeWithKey(stringKey, item: try propertyListObject.propertyListItem())
        }

        return .DictionaryNode(dictionaryNode)
    }
}


extension NSNumber: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        let value: PropertyListValue = NSNumber(bool: true).objCType == self.objCType ? .BooleanValue(self) : .NumberValue(self)
        return .Value(value)
    }
}


extension NSString: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .Value(.StringValue(self))
    }
}
