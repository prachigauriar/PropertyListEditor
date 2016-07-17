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


// MARK: Block-Based Undo

extension UndoManager {
    /// Records an undo operation that executes the specified block.
    /// - parameter handler: The block to execute when undoing.
    /// - returns: The undo manager on which the method was invoked. This is useful when chaining
    ///       multiple method invocations is desired.
    @discardableResult func registerUndo(with handler: (Void) -> Void) -> Self {
        let target = UndoHandlerTarget(handler: handler)
        target.register(with: self)
        return self
    }
}


/// Instances of `UndoHandlerTarget` act as the target for block-based undo operations. They should
/// not be used directly; Instead, use `-[NSUndoManager registerUndoWithHandler:]`.
class UndoHandlerTarget : NSObject {
    /// The block that is executed when the instance’s undo: method is invoked.
    let handler: (Void) -> Void


    /// Initializes the target with the specified handler block.
    /// - parameter handler: The block to execute when the instance’s `undo:` method is invoked.
    init(handler: (Void) -> Void) {
        self.handler = handler
        super.init()
    }


    /// Registers the instance as a target for an undo operation with the specified undo manager.
    /// - parameter undoManager: The undo manager with which to register.
    func register(with undoManager: UndoManager) {
        undoManager.registerUndo(withTarget: self, selector: #selector(UndoHandlerTarget.undo(_:)), object: self)
    }


    /// Simply invokes the instance’s handler block.
    ///
    /// - parameter sender: This parameter is ignored.
    func undo(_ sender: AnyObject?) -> Void {
        handler()
    }
}


// MARK:
// MARK: Debug Helpers

extension UndoManager {
    /// Returns a debug description of the instance’s undo stack.
    /// - warning: This method should only be used for debugging; it uses undocumented, unsupported
    ///     behavior.
    var undoStackDebugDescription: String? {
        let undoStack = object_getIvar(self, class_getInstanceVariable(NSClassFromString("NSUndoManager"), "_undoStack"));
        return undoStack.debugDescription
    }


    /// Returns a debug description of the instance’s redo stack.
    /// - warning: This method should only be used for debugging; it uses undocumented, unsupported behavior.
    var redoStackDebugDescription: String? {
        let redoStack = object_getIvar(self, class_getInstanceVariable(NSClassFromString("NSUndoManager"), "_redoStack"));
        return redoStack.debugDescription
    }
}
