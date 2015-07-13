//
//  PropertyListValue.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


struct PropertyListValidValue {
    let value: AnyObject
    let description: String
}


enum PropertyListValueConstraint {
    case Formatter(NSFormatter)
    case ValueArray([PropertyListValidValue])
}


enum PropertyListValue: CustomStringConvertible {
    case BooleanValue(Bool)
    case DataValue(NSData)
    case DateValue(NSDate)
    case NumberValue(NSNumber)
    case StringValue(String)


    var description: String {
        switch self {
        case let .BooleanValue(boolean):
            return boolean.description
        case let .DataValue(data):
            return data.description
        case let .DateValue(date):
            return date.description
        case let .NumberValue(number):
            return number.description
        case let .StringValue(string):
            return string
        }
    }

    
    var valueConstraint: PropertyListValueConstraint? {
        switch self {
        case .BooleanValue:
            let falseValidValue = PropertyListValidValue(value: false, description: NSLocalizedString("NO", comment: "Label for Boolean false value"))
            let trueValidValue = PropertyListValidValue(value: true, description: NSLocalizedString("YES", comment: "Label for Boolean true value"))
            return .ValueArray([falseValidValue, trueValidValue])
        case .DataValue:
            return nil
        case .DateValue:
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            return .Formatter(dateFormatter)
        case .NumberValue:
            return .Formatter(NSNumberFormatter())
        case .StringValue:
            return nil
        }
    }
}