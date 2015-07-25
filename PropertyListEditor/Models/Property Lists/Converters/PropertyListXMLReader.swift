//
//  PropertyListXMLReader.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/23/2015.
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


/// The `PropertyListXMLReaderError` enum declares errors that can occur when reading data in the
/// property list XML format.
enum PropertyListXMLReaderError: ErrorType {
    /// Indicates that the XML for the property list is invalid. 
    case InvalidXML
}


/// Instances of `PropertyListXMLReader` read Property List XML data and return a property list item
/// representation of that data. These should be used to read Property List XML files instead of
/// using `NSPropertyListSerialization`s, as `PropertyListXMLReaders` create dictionaries whose
/// key/value pairs are ordered the same as in the XML.
class PropertyListXMLReader: NSObject {
    /// The property list item that the reader has read.
    private var propertyListItem: PropertyListItem?
    
    /// The XML data that the reader reads.
    let XMLData: NSData


    /// Initializes a new `PropertyListXMLReader` with the specified XML data.
    /// - parameter XMLData: The XML data that the instance should read.
    init(XMLData: NSData) {
        self.XMLData = XMLData
        super.init()
    }


    /// Reads the instance’s XML data and returns the resulting property list item. If the reader has
    /// previously read the data, it simply returns the property list item that resulted from the 
    /// previous read.
    /// 
    /// - throws: `PropertyListXMLReaderError.InvalidXML` if the instance’s XML data is not valid 
    ///       Property List XML data.
    /// - returns: A `PropertyListItem` representation of the instance’s XML data.
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


/// This private extension adds the ability to create a new `PropertyListItem` with an XML element. It
/// is used by `‑[PropertyListXMLReader readData]` to recursively create a property list item from a
/// Property List XML document’s root element.
private extension PropertyListItem {
    /// Returns the property list item representation of the specified XML element. Returns nil if the
    /// element cannot be represented using a property list item.
    /// - parameter XMLElement: The XML element
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
