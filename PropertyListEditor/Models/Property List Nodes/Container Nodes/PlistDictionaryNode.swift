//
//  PlistDictionaryNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class DictionaryItemNode: PlistChildNode {
    var key: String
    var valueNode: PlistNode


    init(key: String, valueNode: PlistNode) {
        self.key = key
        self.valueNode = valueNode
    }
}


class DictionaryNode: PlistContainerNode {
    var childNodes: [DictionaryItemNode] = []


    func keyForChildAtIndex(index: Int) -> String {
        assert(index >= 0 && index < self.childNodes.count)
        return self.childNodes[index].key
    }
}
