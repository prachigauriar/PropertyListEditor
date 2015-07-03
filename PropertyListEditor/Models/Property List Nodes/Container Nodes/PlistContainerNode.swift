//
//  PlistContainerNode.swift
//  PlistEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


protocol PlistContainerNode: PlistNode {
    typealias ItemNodeType


    var childNodes: [ItemNodeType] { get set }
    func keyForChildAtIndex(index: Int) -> String
}


extension PlistContainerNode {
    func summaryString() -> String {
        let formatString = NSLocalizedString("(%d item(s))", comment: "Summary string for parent nodes")
        return NSString.localizedStringWithFormat(formatString, self.childNodes.count) as String
    }
}


protocol PlistChildNode: PlistNode {
    var valueNode: PlistNode { get set }
}


extension PlistChildNode {
    func summaryString() -> String {
        return self.valueNode.summaryString()
    }
}
