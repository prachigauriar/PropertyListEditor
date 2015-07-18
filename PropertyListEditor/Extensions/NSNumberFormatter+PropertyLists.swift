//
//  NSNumberFormatter+PropertyLists.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/16/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension NSNumberFormatter {
    class func propertyListNumberFormatter() -> NSNumberFormatter {
        struct SharedFormatter {
            static let numberFormatter: NSNumberFormatter = {
                let numberFormatter = NSNumberFormatter()
                numberFormatter.minimumFractionDigits = 0
                numberFormatter.maximumFractionDigits = 10
                return numberFormatter
            }()
        }

        return SharedFormatter.numberFormatter
    }
}
