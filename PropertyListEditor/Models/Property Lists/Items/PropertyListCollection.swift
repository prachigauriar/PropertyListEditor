//
//  PropertyListCollection.swift
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


protocol PropertyListCollection: CustomStringConvertible, Hashable {
    typealias ElementType: CustomStringConvertible, Hashable

    var elements: [ElementType] { get }
    var elementCount: Int { get }

    func elementAtIndex(index: Int) -> ElementType

    mutating func addElement(element: ElementType)
    mutating func insertElement(element: ElementType, atIndex index: Int)
    mutating func moveElementAtIndex(index oldIndex: Int, toIndex newIndex: Int)
    mutating func replaceElementAtIndex(index: Int, withElement element: ElementType)
    mutating func removeElementAtIndex(index: Int) -> ElementType
}


extension PropertyListCollection {
    var description: String {
        return "[" + ", ".join(self.elements.map { $0.description }) + "]"
    }


    var hashValue: Int {
        return self.elementCount
    }


    var elementCount: Int {
        return self.elements.count
    }


    func elementAtIndex(index: Int) -> ElementType {
        return self.elements[index]
    }


    mutating func addElement(element: ElementType) {
        self.insertElement(element, atIndex: self.elementCount)
    }

    
    mutating func moveElementAtIndex(index oldIndex: Int, toIndex newIndex: Int) {
        let element = self.elementAtIndex(oldIndex)
        self.removeElementAtIndex(oldIndex)
        self.insertElement(element, atIndex: newIndex)
    }


    mutating func replaceElementAtIndex(index: Int, withElement element: ElementType) {
        self.removeElementAtIndex(index)
        self.insertElement(element, atIndex: index)
    }
}


func ==<CollectionType: PropertyListCollection>(lhs: CollectionType, rhs: CollectionType) -> Bool {
    return lhs.elements == rhs.elements
}