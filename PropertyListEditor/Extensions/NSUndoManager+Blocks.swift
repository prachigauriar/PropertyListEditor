//
//  NSUndoManager+Blocks.swift
//  PropertyListEditor
//
//  Created by Prachi Gauriar on 7/18/2015.
//  Copyright © 2015 Quantum Lens Cap. All rights reserved.
//

import Foundation
import ObjectiveC.runtime


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


extension NSUndoManager {
    var undoStackDebugDescription: String? {
        let undoStack = object_getIvar(self, class_getInstanceVariable(NSClassFromString("NSUndoManager"), "_undoStack"));
        return undoStack.debugDescription
    }


    var redoStackDebugDescription: String? {
        let redoStack = object_getIvar(self, class_getInstanceVariable(NSClassFromString("NSUndoManager"), "_redoStack"));
        return redoStack.debugDescription
    }


    func registerUndoWithHandler(handler: Void -> Void) -> Self {
        let target = UndoHandlerTarget(handler: handler)
        self.registerUndoWithTarget(target, selector: "undo:", object: target)
        return self
    }
}