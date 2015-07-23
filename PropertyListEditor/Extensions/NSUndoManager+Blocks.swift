//
//  NSUndoManager+Blocks.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/18/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import ObjectiveC.runtime


// MARK: - Block-Based Undo

extension NSUndoManager {
    func registerUndoWithHandler(handler: Void -> Void) -> Self {
        let target = UndoHandlerTarget(handler: handler)
        self.registerUndoWithTarget(target, selector: "undo:", object: target)
        return self
    }
}


class UndoHandlerTarget: NSObject {
    let handler: Void -> Void


    init(handler: Void -> Void) {
        self.handler = handler
        super.init()
    }


    func undo(sender: AnyObject?) -> Void {
        self.handler()
    }
}


// MARK: - Debug Helpers

extension NSUndoManager {
    var undoStackDebugDescription: String? {
        let undoStack = object_getIvar(self, class_getInstanceVariable(NSClassFromString("NSUndoManager"), "_undoStack"));
        return undoStack.debugDescription
    }


    var redoStackDebugDescription: String? {
        let redoStack = object_getIvar(self, class_getInstanceVariable(NSClassFromString("NSUndoManager"), "_redoStack"));
        return redoStack.debugDescription
    }
}
