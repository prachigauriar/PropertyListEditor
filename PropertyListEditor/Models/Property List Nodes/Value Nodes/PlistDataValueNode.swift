//
//  PlistDataValueNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PlistDataValueNode: PlistValueNode {
    var value: NSData = NSData()
    static let valueConstraint: PlistValueConstraint<NSData>? = .Formatter(formatter: Base64DataFormatter())

    func summaryString() -> String {
        return self.value.description
    }
}