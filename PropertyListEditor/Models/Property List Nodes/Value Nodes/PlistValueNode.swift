//
//  PlistValueNode.swift
//  PlistEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


struct PlistValidValue<T> {
    let value: T
    let description: String
}


enum PlistValueConstraint<T> {
    case Formatter(formatter: NSFormatter)
    case ValueArray(valueArray: [PlistValidValue<T>])
}


protocol PlistValueNode: PlistNode {
    typealias ValueType

    var value: ValueType { get set }
    static var valueConstraint: PlistValueConstraint<ValueType>? { get }
}
