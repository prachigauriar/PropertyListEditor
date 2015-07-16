//
//  PropertyListDataFormatter.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/9/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class PropertyListDataFormatter: NSFormatter {
    func dataFromString(string: NSString) -> NSData? {
        var data: AnyObject?
        self.getObjectValue(&data, forString: string as String, errorDescription: nil)
        return data as? NSData
    }


    override func stringForObjectValue(obj: AnyObject) -> String? {
        if let data = obj as? NSData {
            return data.description
        } else {
            return nil
        }
    }


    override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>,
        forString string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
            // Start by removing all spaces in the string and getting a character generator that we can
            // use to iterate over each character
            var characterGenerator = string.stringByReplacingOccurrencesOfString(" ", withString: "").characters.generate()

            // If the string didn’t start with a <, it’s invalid
            guard let firstCharacter = characterGenerator.next() where firstCharacter == "<" else {
                return false
            }

            // Otherwise, build up our data by continuously appending bytes until we reach a >
            var byteBuffer: [UInt8] = []
            repeat {
                // Read the first character. If there wasn’t one, return false
                guard let char1 = characterGenerator.next() else {
                    return false
                }

                // If the first character was a >, we’re done parsing, so break out of the loop
                if char1 == ">" {
                    break
                }

                // Otherwise, assume we got a hex character. Read a second hex character to form
                // a byte. If we can’t create a valid byte from the two hex characters, the string
                // was invalid, so we should return false
                guard let char2 = characterGenerator.next(), byte = UInt8("\(char1)\(char2)", radix: 16) else {
                    return false
                }

                // Otherwise, everything went fine, so add our byte to our data object
                byteBuffer.append(byte)
            } while true

            obj.memory = NSData(bytes: &byteBuffer, length: byteBuffer.count)
            return true
    }
}
