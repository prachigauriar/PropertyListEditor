//
//  Base64DataFormatter.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class Base64DataFormatter: NSFormatter {
    override func stringForObjectValue(obj: AnyObject) -> String? {
        guard let data = obj as? NSData else {
            return nil
        }

        return data.base64EncodedStringWithOptions([])
    }


    override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>,
        forString string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
            guard let data = NSData(base64EncodedString: string, options: []) else {
                return false
            }

            obj.memory = data
            return true
    }
}
