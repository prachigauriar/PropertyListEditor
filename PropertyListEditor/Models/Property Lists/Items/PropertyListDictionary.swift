//
//  PropertyListDictionary.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
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


struct PropertyListKeyValuePair: CustomStringConvertible, Hashable {
    let key: String
    let value: PropertyListItem

    
    var description: String {
        return "\"\(self.key)\": \(self.value)"
    }


    var hashValue: Int {
        return key.hashValue ^ value.hashValue
    }


    func keyValuePairBySettingKey(key: String) -> PropertyListKeyValuePair {
        return PropertyListKeyValuePair(key: key, value: self.value)
    }


    func keyValuePairBySettingValue(value: PropertyListItem) -> PropertyListKeyValuePair {
        return PropertyListKeyValuePair(key: self.key, value: value)
    }
}


func ==(lhs: PropertyListKeyValuePair, rhs: PropertyListKeyValuePair) -> Bool {
    return lhs.key == rhs.key && lhs.value == rhs.value
}


struct PropertyListDictionary: PropertyListCollection {
    typealias ElementType = PropertyListKeyValuePair
    private(set) var elements: [PropertyListKeyValuePair] = []
    private var keySet = Set<String>()


    var objectValue: AnyObject {
        let dictionary = NSMutableDictionary()

        for element in self.elements {
            dictionary[element.key] = element.value.objectValue
        }

        return dictionary.copy()
    }


    func containsKey(key: String) -> Bool {
        return self.keySet.contains(key)
    }


    mutating func insertElement(element: ElementType, atIndex index: Int) {
        assert(!self.keySet.contains(element.key), "dictionary already contains key \"\(element.key)\"")
        self.keySet.insert(element.key)
        self.elements.insert(element, atIndex: index)
    }


    mutating func removeElementAtIndex(index: Int) -> ElementType {
        let element = self.elements[index]
        self.keySet.remove(element.key)
        return self.elements.removeAtIndex(index)
    }


    // MARK: - Key-Value Pair Methods

    mutating func addKey(key: String, value: PropertyListItem) {
        self.insertKey(key, value: value, atIndex: self.elementCount)
    }


    mutating func insertKey(key: String, value: PropertyListItem, atIndex index: Int) {
        self.insertElement(PropertyListKeyValuePair(key: key, value: value), atIndex: index)
    }


    mutating func setKey(key: String, value: PropertyListItem, atIndex index: Int) {
        self.replaceElementAtIndex(index, withElement:PropertyListKeyValuePair(key: key, value: value))
    }


    mutating func setKey(key: String, atIndex index: Int) {
        let keyValuePair = self.elementAtIndex(index)
        self.replaceElementAtIndex(index, withElement: keyValuePair.keyValuePairBySettingKey(key))
    }


    mutating func setValue(value: PropertyListItem, atIndex index: Int) {
        let keyValuePair = self.elementAtIndex(index)
        self.replaceElementAtIndex(index, withElement: keyValuePair.keyValuePairBySettingValue(value))
    }
}
