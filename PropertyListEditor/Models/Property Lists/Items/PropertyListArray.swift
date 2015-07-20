//
//  PropertyListArray.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


struct PropertyListArray: PropertyListCollection {
    typealias ElementType = PropertyListItem
    private(set) var elements: [PropertyListItem] = []


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
