//
//  PlistDateValueNode.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


class PlistDateValueNode: PlistValueNode {
    var value: NSDate = NSDate()
    static let valueConstraint: PlistValueConstraint<NSDate>? = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        return .Formatter(formatter: dateFormatter)
    }()


    func summaryString() -> String {
        return self.value.description
    }
}