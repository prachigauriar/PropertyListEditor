//
//  PropertyListValue.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


struct PropertyListValidValue {
    let value: PropertyListObject
    let title: String
}


enum PropertyListValueConstraint {
    case Formatter(NSFormatter)
    case ValueArray([PropertyListValidValue])
}


enum PropertyListValue: CustomStringConvertible {
    case BooleanValue(NSNumber)
    case DataValue(NSData)
    case DateValue(NSDate)
    case NumberValue(NSNumber)
    case StringValue(NSString)


    var description: String {
        switch self {
        case let .BooleanValue(boolean):
            if boolean.boolValue {
                return NSLocalizedString("YES", comment: "Title for Boolean true value")
            } else {
                return NSLocalizedString("NO", comment: "Title for Boolean false value")
            }
        case let .DataValue(data):
            return data.description
        case let .DateValue(date):
            return date.description
        case let .NumberValue(number):
            return number.description
        case let .StringValue(string):
            return string.description
        }
    }


    var objectValue: AnyObject {
        switch self {
        case let .BooleanValue(boolean):
            return boolean
        case let .DataValue(data):
            return data
        case let .DateValue(date):
            return date
        case let .NumberValue(number):
            return number
        case let .StringValue(string):
            return string
        }
    }


    var valueConstraint: PropertyListValueConstraint? {
        switch self {
        case .BooleanValue:
            let falseValidValue = PropertyListValidValue(value: NSNumber(bool: false), title: NSLocalizedString("NO", comment: "Title for Boolean false value"))
            let trueValidValue = PropertyListValidValue(value: NSNumber(bool: true), title: NSLocalizedString("YES", comment: "Title for Boolean true value"))
            return .ValueArray([falseValidValue, trueValidValue])
        case .DataValue:
            return .Formatter(PropertyListDataFormatter())
        case .DateValue:
            return .Formatter(NSDateFormatter.propertyListDateFormatter())
        case .NumberValue:
            return .Formatter(NSNumberFormatter.propertyListNumberFormatter())
        case .StringValue:
            return nil
        }
    }
}


extension NSDateFormatter {
    class func propertyListDateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        return dateFormatter
    }
}


extension NSNumberFormatter {
    class func propertyListNumberFormatter() -> NSNumberFormatter {
        return NSNumberFormatter()
    }
}