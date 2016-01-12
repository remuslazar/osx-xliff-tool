//
//  EditableTextField.swift
//  xliff-tool
//
//  Created by Remus Lazar on 12.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class EditableTextField: NSTextField {
    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            if let textView = window?.firstResponder as? NSTextView {
                textView.continuousSpellCheckingEnabled = true
            }
            return true
        }
        return false
    }
    
}
