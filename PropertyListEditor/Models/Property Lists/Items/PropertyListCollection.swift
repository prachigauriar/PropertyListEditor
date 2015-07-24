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


/// The `PropertyListCollection` protocol defines a set of properties and methods that all property
/// collections provide. It is primarily useful for providing default behavior using a protocol
/// extension.
protocol PropertyListCollection: CustomStringConvertible, Hashable {
    /// The type of element the instance contains.
    typealias ElementType: CustomStringConvertible, Hashable

    /// The elements in the instance
    var elements: [ElementType] { get }

    /// The number of elements in the instance
    var elementCount: Int { get }


    /// Returns the element at the specified index in the instance.
    /// - parameter index: The index. Raises an assertion if beyond the bounds of the instance.
    /// - returns: The element at the specified index in the instance.
    func elementAtIndex(index: Int) -> ElementType


    /// Adds the specified element to the end of the instance.
    /// - parameter element: The element to add
    mutating func addElement(element: ElementType)

    /// Inserts the specified element at the specified index in the instance.
    /// - parameter element: The element to insert
    /// - parameter index: The index at which to insert the element. Raises an assertion if beyond
    ///       the bounds of the instance.
    mutating func insertElement(element: ElementType, atIndex index: Int)


    /// Moves the element from the specified index to the new index.
    /// - parameter oldIndex: The index of the element being moved. Raises an assertion if beyond
    ///       the bounds of the instance.
    /// - parameter newIndex: The index to which to move the element. Raises an assertion if beyond
    ///       the bounds of the instance.
    mutating func moveElementAtIndex(oldIndex: Int, toIndex newIndex: Int)


    /// Replaces the element at the specified index with the specified element.
    /// - parameter index: The index of the element being replaced. Raises an assertion if beyond
    ///       the bounds of the instance.
    /// - parameter element: The element to replace the element at the specified index.
    mutating func replaceElementAtIndex(index: Int, withElement element: ElementType)


    /// Removes the element at the specified index.
    /// - parameter index: The index of the element being removed. Raises an assertion if beyond
    ///       the bounds of the instance.
    /// - returns: The element that was removed.
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

    
    mutating func moveElementAtIndex(oldIndex: Int, toIndex newIndex: Int) {
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
