//
//  Document.swift
//  xliff-tool
//
//  Created by Remus Lazar on 06.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    var xliffDocument: XMLDocument!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        return xliffDocument.xmlData
//        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    private class func getXMLDocument(from data: Data) throws -> XMLDocument {
        do {
            return try XMLDocument(data: data, options: Int(
                XMLNode.Options.nodePreserveWhitespace.rawValue
                    | XMLNode.Options.nodeCompactEmptyElement.rawValue
            ))
        } catch (let error as NSError) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
                NSLocalizedFailureReasonErrorKey: error.localizedDescription
                ])
        }
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        self.xliffDocument = try Document.getXMLDocument(from: data)

        // try to read/parse the full document (without filtering) to potentially throw an error prior to opening it
        try _ = XliffFile(xliffDocument: xliffDocument)
    }
    
    @IBAction func reloadDocument(_ sender: AnyObject?) {
        let controller = NSDocumentController.shared()
        controller.currentDocument?.savePresentedItemChanges() { (error) in
        self.close()
            controller.reopenDocument(for: self.fileURL!, withContentsOf: self.fileURL!, display: true) { _,_,_ in }
        }
    }

}

