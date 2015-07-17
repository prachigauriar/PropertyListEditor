//
//  PropertyListValue.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/3/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


struct PropertyListValidValue {
    let value: PropertyListItemConvertible
    let title: String
}


enum PropertyListValueConstraint {
    case Formatter(NSFormatter)
    case ValueArray([PropertyListValidValue])
}


enum PropertyListValue: CustomStringConvertible, Hashable {
    case BooleanValue(NSNumber)
    case DataValue(NSData)
    case DateValue(NSDate)
    case NumberValue(NSNumber)
    case StringValue(NSString)


    var description: String {
        switch self {
        case let .BooleanValue(boolean):
            if boolean.boolValue {
                return NSLocalizedString("PropertyListValue.Boolean.TrueTitle", comment: "Title for Boolean true value")
            } else {
                return NSLocalizedString("PropertyListValue.Boolean.FalseTitle", comment: "Title for Boolean false value")
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
            let falseTitle = NSLocalizedString("PropertyListValue.Boolean.FalseTitle", comment: "Title for Boolean false value")
            let falseValidValue = PropertyListValidValue(value: NSNumber(bool: false), title: falseTitle)
            let trueTitle = NSLocalizedString("PropertyListValue.Boolean.TrueTitle", comment: "Title for Boolean true value")
            let trueValidValue = PropertyListValidValue(value: NSNumber(bool: true), title: trueTitle)
            return .ValueArray([falseValidValue, trueValidValue])
        case .DataValue:
            return .Formatter(PropertyListDataFormatter())
        case .DateValue:
            struct SharedFormatter {
                static let dateFormatter = LenientDateFormatter()
            }

            return .Formatter(SharedFormatter.dateFormatter)
        case .NumberValue:
            return .Formatter(NSNumberFormatter.propertyListNumberFormatter())
        case .StringValue:
            return nil
        }
    }


    // MARK: - Hashable
    
    var hashValue: Int {
        switch self {
        case let .BooleanValue(boolean):
            return boolean.hashValue
        case let .DataValue(data):
            return data.hashValue
        case let .DateValue(date):
            return date.hashValue
        case let .NumberValue(number):
            return number.hashValue
        case let .StringValue(string):
            return string.hashValue
        }
    }
}


func ==(lhs: PropertyListValue, rhs: PropertyListValue) -> Bool {
    switch (lhs, rhs) {
    case let (.BooleanValue(left), .BooleanValue(right)):
        return left == right
    case let (.DataValue(left), .DataValue(right)):
        return left == right
    case let (.DateValue(left), .DateValue(right)):
        return left == right
    case let (.NumberValue(left), .NumberValue(right)):
        return left == right
    case let (.StringValue(left), .StringValue(right)):
        return left == right
    default:
        return false
    }
}