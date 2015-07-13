//
//  NSMutableData+AppendByte.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/11/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension NSMutableData {
    /// Appends a single byte to the receiver.
    /// :byte: The byte to append
    func appendByte(var byte: UInt8) {
        self.appendBytes(&byte, length: 1)
    }
}
