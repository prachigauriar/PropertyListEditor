//
//  NSDateFormatter+PropertyListDateOutputFormatter.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/16/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension NSDateFormatter {
    class func propertyListDateOutputFormatter() -> NSDateFormatter {
        struct SharedFormatter {
            static let dateFormatter: NSDateFormatter = {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = .LongStyle
                dateFormatter.timeStyle = .MediumStyle
                return dateFormatter
            }()
        }

        return SharedFormatter.dateFormatter
    }
}
