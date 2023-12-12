//
//  Data+HexString.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 9/6/2019.
//  Copyright © 2019 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension Data {
    var hexString: String {
        var string = "<"
        
        for (i, byte) in self.enumerated() {
            string.append(String(format: "%x", byte))
            if i % 4 == 3 && i != (count - 1) {
                string.append(" ")
            }
        }
        
        string.append(">")
        return string
    }
}
