//
//  NSIndexPath+Indexes.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/19/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation


extension NSIndexPath {
    convenience init(indexes: Int...) {
        self.init(indexes: indexes, length: indexes.count)
    }


    var indexes: [Int] {
        var indexArray: [Int] = Array<Int>(count: self.length, repeatedValue: 0)
        self.getIndexes(&indexArray, range: NSRange(location: 0, length: self.length))
        return indexArray
    }


    var lastIndex: Int? {
        guard self.length != 0 else {
            return nil
        }

        return self.indexAtPosition(self.length - 1)
    }
}
