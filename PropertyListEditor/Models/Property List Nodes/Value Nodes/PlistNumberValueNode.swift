//
//  PlistNumberValueNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PlistNumberValueNode: PlistValueNode {
    var value: NSNumber = 0
    static let valueConstraint: PlistValueConstraint<NSNumber>? = .Formatter(formatter: NSNumberFormatter())


    func summaryString() -> String {
        return self.value.description
    }
}