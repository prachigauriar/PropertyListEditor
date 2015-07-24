//
//  PropertyListArray.swift
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


/// PropertyListArrays represent arrays of property list items.
struct PropertyListArray: PropertyListCollection {
    typealias ElementType = PropertyListItem
    private(set) var elements: [PropertyListItem] = []


    /// Returns an object representation of the instance.
    var objectValue: AnyObject {
        return self.elements.map { $0.objectValue } as NSArray
    }


    mutating func insertElement(element: ElementType, atIndex index: Int) {
        self.elements.insert(element, atIndex: index)
    }


    mutating func replaceElementAtIndex(index: Int, withElement element: ElementType) {
        self.elements[index] = element
    }


    mutating func removeElementAtIndex(index: Int) -> ElementType {
        return self.elements.removeAtIndex(index)
    }
}
