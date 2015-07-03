//
//  PlistBooleanValueNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PlistBooleanValueNode: PlistValueNode {
    var value: Bool = false
    static let valueConstraint: PlistValueConstraint<Bool>? = {
        let falseValidValue = PlistValidValue<Bool>(value: false, description: NSLocalizedString("NO", comment: "Label for Boolean false value"))
        let trueValidValue = PlistValidValue<Bool>(value: true, description: NSLocalizedString("YES", comment: "Label for Boolean true value"))
        return .ValueArray(valueArray: [falseValidValue, trueValidValue])
    }()


    func summaryString() -> String {
        return self.value.description
    }
}