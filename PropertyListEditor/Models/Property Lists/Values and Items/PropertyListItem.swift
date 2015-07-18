//
//  PropertyListItem.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/17/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


enum PropertyListType: String {
    case ArrayType, BooleanType, DataType, DateType, DictionaryType, NumberType, StringType
}


/// PropertyListItems contain the data that is stored in a property list node. An item contains either
/// a PropertyListValue, a PropertyListArrayNode, or a PropertyListDictionaryNode
enum PropertyListItem {
    /// Indicates that the item is a value type, i.e., a boolean, data, date, number, or string.
    case Value(PropertyListValue)

    /// Indicates that the item is an array node
    case ArrayNode(PropertyListArrayNode)

    /// Indicates that the item is a dictionary node
    case DictionaryNode(PropertyListDictionaryNode)


    /// The property list type of the item
    var propertyListType: PropertyListType {
        switch self {
        case .ArrayNode:
            return .ArrayType
        case .DictionaryNode:
            return .DictionaryType
        case let .Value(value):
            switch value {
            case .BooleanValue:
                return .BooleanType
            case .DataValue:
                return .DataType
            case .DateValue:
                return .DateType
            case .NumberValue:
                return .NumberType
            case .StringValue:
                return .StringType
            }
        }
    }


    func appendXMLNodeToParentElement(parentElement: NSXMLElement) {
        switch self {
        case let .Value(value):
            let valueElement: NSXMLElement

            switch value {
            case let .BooleanValue(boolean):
                valueElement = NSXMLElement(name: boolean.boolValue ? "true" : "false")
            case let .DataValue(data):
                valueElement = NSXMLElement(name: "data", stringValue: data.base64EncodedStringWithOptions([]))
            case let .DateValue(date):
                valueElement = NSXMLElement(name: "date", stringValue: NSDateFormatter.propertyListXMLDateFormatter().stringFromDate(date))
            case let .NumberValue(number):
                let doubleValue = number.doubleValue
                if trunc(doubleValue) == doubleValue {
                    valueElement = NSXMLElement(name: "integer", stringValue: "\(number.integerValue)")
                } else {
                    valueElement = NSXMLElement(name: "real", stringValue: "\(doubleValue)")
                }
            case let .StringValue(string):
                valueElement = NSXMLElement(name: "string", stringValue: string as String)
            }

            parentElement.addChild(valueElement)
        case let .ArrayNode(arrayNode):
            arrayNode.appendXMLNodeToParentElement(parentElement)
        case let .DictionaryNode(dictionaryNode):
            dictionaryNode.appendXMLNodeToParentElement(parentElement)
        }
    }

}
