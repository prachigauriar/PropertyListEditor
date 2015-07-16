//
//  LenientDateFormatter.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/16/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Cocoa


class LenientDateFormatter: NSFormatter {
    func dateFromString(string: NSString) -> NSDate? {
        var date: AnyObject?
        self.getObjectValue(&date, forString: string as String, errorDescription: nil)
        return date as? NSDate
    }


    override func stringForObjectValue(obj: AnyObject) -> String? {
        return self.propertyListDateFormatter().stringForObjectValue(obj)
    }


    override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>,
        forString string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
            do {
                let detector = try NSDataDetector(types: NSTextCheckingType.Date.rawValue)
                let matches = detector.matchesInString(string, options: NSMatchingOptions(), range: NSRange(location: 0, length: string.characters.count))

                for match in matches where match.date != nil {
                    obj.memory = match.date
                    return true
                }
            } catch {
                return false
            }


            return false
    }


    private func propertyListDateFormatter() -> NSDateFormatter {
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
