//
//  PlistArrayNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class ArrayItemNode: PlistChildNode {
    var valueNode: PlistNode


    init(valueNode: PlistNode) {
        self.valueNode = valueNode
    }
}


class ArrayNode: PlistContainerNode {
    var childNodes: [ArrayItemNode] = []


    func keyForChildAtIndex(index: Int) -> String {
        assert(index >= 0 && index < self.childNodes.count)
        let formatString = NSLocalizedString("(Item %d)", comment: "Key for array item node")
        return NSString.localizedStringWithFormat(formatString, index) as String
    }
}
