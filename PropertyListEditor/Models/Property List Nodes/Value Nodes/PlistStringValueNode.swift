//
//  PlistStringValueNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PlistStringValueNode: PlistValueNode {
    var value: String = ""
    static var valueConstraint: PlistValueConstraint<String>?


    func summaryString() -> String {
        return self.value
    }
}