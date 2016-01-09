//
//  WindowController.swift
//  xliff-tool
//
//  Created by Remus Lazar on 09.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override var document: AnyObject? {
        didSet {
            // pass the document instance to the asociated view controller
            let viewController = window!.contentViewController as! ViewController
            viewController.document = document as? Document
        }
    }

}
