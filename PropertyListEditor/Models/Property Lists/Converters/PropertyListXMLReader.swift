//
//  PropertyListXMLReader.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/23/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


enum PropertyListXMLReaderError: ErrorType {
    case InvalidXML
}


class PropertyListXMLReader: NSObject {
    private var propertyListItem: PropertyListItem?
    let XMLData: NSData


    init(XMLData: NSData) {
        self.XMLData = XMLData
        super.init()
    }


    func readData() throws -> PropertyListItem {
        if let propertyListItem = self.propertyListItem {
            return propertyListItem
        }

        let XMLDocument = try NSXMLDocument(data: self.XMLData, options: 0)
        guard let propertyListXMLElement = XMLDocument.rootElement()?.children?.first as? NSXMLElement,
            let propertyListItem = PropertyListItem.init(XMLElement: propertyListXMLElement) else {
                throw PropertyListXMLReaderError.InvalidXML
        }

        self.propertyListItem = propertyListItem
        return propertyListItem
    }
}


private extension PropertyListItem {
    init?(XMLElement: NSXMLElement) {
        guard let elementName = XMLElement.name else {
            return nil
        }

        switch elementName {
        case "array":
            var array = PropertyListArray()

            if let children = XMLElement.children {
                for childXMLNode in children where childXMLNode is NSXMLElement {
                    let childXMLElement = childXMLNode as! NSXMLElement
                    guard let element = PropertyListItem(XMLElement: childXMLElement) else {
                        return nil
                    }

                    array.addElement(element)
                }
            }

            self = .ArrayItem(array)
        case "dict":
            var dictionary = PropertyListDictionary()

            if let children = XMLElement.children {
                guard children.count % 2 == 0 else {
                    return nil
                }

                var childGenerator = children.generate()

                while let keyNode = childGenerator.next() {
                    guard let keyElement = keyNode as? NSXMLElement where keyElement.name == "key",
                        let key = keyElement.stringValue where !dictionary.containsKey(key),
                        let valueElement = childGenerator.next() as? NSXMLElement,
                        let value = PropertyListItem(XMLElement: valueElement) else {
                            return nil
                    }

                    dictionary.addKey(key, value: value)
                }
            }

            self = .DictionaryItem(dictionary)
        case "data":
            guard let base64EncodedString = XMLElement.stringValue,
                let data = NSData(base64EncodedString: base64EncodedString, options: [ .IgnoreUnknownCharacters ]) else {
                    return nil
            }

            self = .DataItem(data)
        case "date":
            guard let dateString = XMLElement.stringValue,
                let date = NSDateFormatter.propertyListXMLDateFormatter().dateFromString(dateString) else {
                    return nil
            }

            self = .DateItem(date)
        case "integer", "real":
            guard let numberString = XMLElement.stringValue,
                let number = NSNumberFormatter.propertyListNumberFormatter().numberFromString(numberString) else {
                    return nil
            }

            self = .NumberItem(number)
        case "true":
            self = .BooleanItem(true)
        case "false":
            self = .BooleanItem(false)
        case "string":
            guard let string = XMLElement.stringValue else {
                return nil
            }

            self = .StringItem(string)
        default:
            return nil
        }
    }
}
