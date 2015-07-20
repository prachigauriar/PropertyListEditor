//
//  PropertyListCollection.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
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