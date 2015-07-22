//
//  PropertyListItem.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
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

import Foundation


enum PropertyListItem: CustomStringConvertible, Hashable {
    case ArrayItem(PropertyListArray)
    case BooleanItem(NSNumber)
    case DataItem(NSData)
    case DateItem(NSDate)
    case DictionaryItem(PropertyListDictionary)
    case NumberItem(NSNumber)
    case StringItem(NSString)


    var description: String {
        switch self {
        case let .ArrayItem(array):
            return array.description
        case let .BooleanItem(boolean):
            return boolean.boolValue ? "true" : "false"
        case let .DataItem(data):
            return data.description
        case let .DateItem(date):
            return date.description
        case let .DictionaryItem(dictionary):
            return dictionary.description
        case let .NumberItem(number):
            return number.description
        case let .StringItem(string):
            return string.description
        }
    }


    var hashValue: Int {
        switch self {
        case let .ArrayItem(array):
            return array.hashValue
        case let .BooleanItem(boolean):
            return boolean.hashValue
        case let .DataItem(data):
            return data.hashValue
        case let .DateItem(date):
            return date.hashValue
        case let .DictionaryItem(dictionary):
            return dictionary.hashValue
        case let .NumberItem(number):
            return number.hashValue
        case let .StringItem(string):
            return string.hashValue
        }
    }


    var isCollection: Bool {
        switch self {
        case .ArrayItem, .DictionaryItem:
            return true
        default:
            return false
        }
    }


    var objectValue: AnyObject {
        switch self {
        case let .ArrayItem(array):
            return array.objectValue
        case let .BooleanItem(value):
            return value
        case let .DataItem(value):
            return value
        case let .DateItem(value):
            return value
        case let .DictionaryItem(dictionary):
            return dictionary.objectValue
        case let .NumberItem(value):
            return value
        case let .StringItem(value):
            return value
        }
    }
}


func ==(lhs: PropertyListItem, rhs: PropertyListItem) -> Bool {
    switch (lhs, rhs) {
    case let (.ArrayItem(left), .ArrayItem(right)):
        return left == right
    case let (.BooleanItem(left), .BooleanItem(right)):
        return left == right
    case let (.DataItem(left), .DataItem(right)):
        return left == right
    case let (.DateItem(left), .DateItem(right)):
        return left == right
    case let (.DictionaryItem(left), .DictionaryItem(right)):
        return left == right
    case let (.NumberItem(left), .NumberItem(right)):
        return left == right
    case let (.StringItem(left), .StringItem(right)):
        return left == right
    default:
        return false
    }
}


// MARK: - Value Constraints

struct PropertyListValidValue {
    let value: PropertyListItemConvertible
    let title: String
}


enum PropertyListValueConstraint {
    case Formatter(NSFormatter)
    case ValueArray([PropertyListValidValue])
}


extension PropertyListItem {
    var valueConstraint: PropertyListValueConstraint? {
        switch self {
        case .BooleanItem:
            let falseTitle = NSLocalizedString("PropertyListValue.Boolean.FalseTitle", comment: "Title for Boolean false value")
            let falseValidValue = PropertyListValidValue(value: NSNumber(bool: false), title: falseTitle)
            let trueTitle = NSLocalizedString("PropertyListValue.Boolean.TrueTitle", comment: "Title for Boolean true value")
            let trueValidValue = PropertyListValidValue(value: NSNumber(bool: true), title: trueTitle)
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


// MARK: - Property List Types

enum PropertyListType {
    case ArrayType, DictionaryType, BooleanType, DataType, DateType, NumberType, StringType
}


extension PropertyListItem {
    var propertyListType: PropertyListType {
        switch self {
        case .ArrayItem:
            return .ArrayType
        case .BooleanItem:
            return .BooleanType
        case .DataItem:
            return .DataType
        case .DateItem:
            return .DateType
        case .DictionaryItem:
            return .DictionaryType
        case .NumberItem:
            return .NumberType
        case .StringItem:
            return .StringType
        }
    }
}


// MARK: - Accessing Items with Index Path

extension PropertyListItem {
    func itemAtIndexPath(indexPath: NSIndexPath) -> PropertyListItem {
        var item = self

        for index in indexPath.indexes {
            switch item {
            case let .ArrayItem(array):
                item = array.elementAtIndex(index)
            case let .DictionaryItem(dictionary):
                item = dictionary.elementAtIndex(index).value
            default:
                assert(false, "non-empty indexPath for scalar type")
            }
        }

        return item
    }


    func itemBySettingItem(newItem: PropertyListItem, atIndexPath indexPath: NSIndexPath) -> PropertyListItem {
        if indexPath.length == 0 {
            return newItem
        }

        return self.itemBySettingItem(newItem, atIndexPath: indexPath, indexPosition: 0)
    }


    private func itemBySettingItem(newItem: PropertyListItem, atIndexPath indexPath: NSIndexPath, indexPosition: Int) -> PropertyListItem {
        if indexPosition == indexPath.length {
            return newItem
        }

        let index = indexPath.indexAtPosition(indexPosition)

        switch self {
        case var .ArrayItem(array):
            let element = array.elementAtIndex(index)
            let newElement = element.itemBySettingItem(newItem, atIndexPath: indexPath, indexPosition: indexPosition + 1)
            array.replaceElementAtIndex(index, withElement:newElement)
            return .ArrayItem(array)
        case var .DictionaryItem(dictionary):
            let value = dictionary.elementAtIndex(index).value
            let newValue = value.itemBySettingItem(newItem, atIndexPath: indexPath, indexPosition: indexPosition + 1)
            dictionary.setValue(newValue, atIndex: index)
            return .DictionaryItem(dictionary)
        default:
            assert(false, "non-empty indexPath for scalar type")
        }
    }
}
