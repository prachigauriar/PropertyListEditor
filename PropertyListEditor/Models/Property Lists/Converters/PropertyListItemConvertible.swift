//
//  PropertyListItemConvertible.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


enum PropertyListItemConversionError: ErrorType, CustomStringConvertible {
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
        var array = PropertyListArray()

        for element in self {
            guard let propertyListObject = element as? PropertyListItemConvertible else {
                throw PropertyListItemConversionError.UnsupportedObjectType(element)
            }

            array.addElement(try propertyListObject.propertyListItem())
        }

        return .ArrayItem(array)
    }
}


extension NSData: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .DataItem(self)
    }
}


extension NSDate: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .DateItem(self)
    }
}


extension NSDictionary: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        var dictionary = PropertyListDictionary()

        for (key, value) in self {
            guard let stringKey = key as? String else {
                throw PropertyListItemConversionError.NonStringDictionaryKey(dictionary: self, key: key)
            }

            guard let propertyListObject = value as? PropertyListItemConvertible else {
                throw PropertyListItemConversionError.UnsupportedObjectType(value)
            }

            dictionary.addKey(stringKey, value: try propertyListObject.propertyListItem())
        }

        return .DictionaryItem(dictionary)
    }
}


extension NSNumber: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return NSNumber(bool: true).objCType == self.objCType ? .BooleanItem(self) : .NumberItem(self)
    }
}


extension NSString: PropertyListItemConvertible {
    func propertyListItem() throws -> PropertyListItem {
        return .StringItem(self)
    }
}
