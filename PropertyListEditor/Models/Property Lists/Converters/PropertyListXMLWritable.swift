//
//  PropertyListXMLWritable.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


protocol PropertyListXMLWritable {
    func addPropertyListXMLElementToParentElement(parentXMLElement: NSXMLElement)
}


extension PropertyListXMLWritable {
    func propertyListXMLDocumentData() -> NSData {
        let baseXMLString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
            "<plist version=\"1.0\"></plist>"

        let XMLDocument = try! NSXMLDocument(XMLString: baseXMLString, options: 0)
        self.addPropertyListXMLElementToParentElement(XMLDocument.rootElement()!)
        return XMLDocument.XMLDataWithOptions(NSXMLNodePrettyPrint | NSXMLNodeCompactEmptyElement)
    }
}


extension PropertyListItem: PropertyListXMLWritable {
    func addPropertyListXMLElementToParentElement(parentXMLElement: NSXMLElement) {
        switch self {
        case let .ArrayItem(array):
            array.addPropertyListXMLElementToParentElement(parentXMLElement)
        case let .BooleanItem(boolean):
            parentXMLElement.addChild(NSXMLElement(name: boolean.boolValue ? "true" : "false"))
        case let .DataItem(data):
            parentXMLElement.addChild(NSXMLElement(name: "data", stringValue: data.base64EncodedStringWithOptions([])))
        case let .DateItem(date):
            parentXMLElement.addChild(NSXMLElement(name: "date", stringValue: NSDateFormatter.propertyListXMLDateFormatter().stringFromDate(date)))
        case let .DictionaryItem(dictionary):
            dictionary.addPropertyListXMLElementToParentElement(parentXMLElement)
        case let .NumberItem(number):
            let doubleValue = number.doubleValue
            if trunc(doubleValue) == doubleValue {
                parentXMLElement.addChild(NSXMLElement(name: "integer", stringValue: "\(number.integerValue)"))
            } else {
                parentXMLElement.addChild(NSXMLElement(name: "real", stringValue: "\(doubleValue)"))
            }
        case let .StringItem(string):
            parentXMLElement.addChild(NSXMLElement(name: "string", stringValue: string as String))
        }
    }
}


extension PropertyListArray: PropertyListXMLWritable {
    func addPropertyListXMLElementToParentElement(parentXMLElement: NSXMLElement) {
        let arrayXMLElement = NSXMLElement(name: "array")
        for element in self.elements {
            element.addPropertyListXMLElementToParentElement(arrayXMLElement)
        }

        parentXMLElement.addChild(arrayXMLElement)
    }
}


extension PropertyListDictionary: PropertyListXMLWritable {
    func addPropertyListXMLElementToParentElement(parentXMLElement: NSXMLElement) {
        let dictionaryXMLElement = NSXMLElement(name: "dict")
        for keyValuePair in self.elements {
            dictionaryXMLElement.addChild(NSXMLElement(name: "key", stringValue: keyValuePair.key))
            keyValuePair.value.addPropertyListXMLElementToParentElement(dictionaryXMLElement)
        }

        parentXMLElement.addChild(dictionaryXMLElement)
    }
}
