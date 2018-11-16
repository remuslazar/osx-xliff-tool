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

    override class var autosavesInPlace: Bool {
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
        
        /**
         We do want to match the original Xcode XLIFF XML document structure:
         
         1) no standalone="yes" attribute in the XML declaration
         2) trailing newline (at the end of the file)
         3) a new line between the XML declaration and XML body
         
         */
        
        // 1) don't add the standalone="yes" attribute to the XML declaration
        xliffDocument.isStandalone = false

        var xmlString = xliffDocument.xmlString.replacingOccurrences(of: XliffFile.idAttrLineBraakEscapeSequence,
                                                                     with: "&#10;")

        // 2) add a newline between the XML declaration and body, if needed
        let regex = try! NSRegularExpression(pattern: "<\\?xml.+\\?>(?!\n)", options: .caseInsensitive)

        let firstRange = regex.rangeOfFirstMatch(in: xmlString, range: NSRange(location: 0, length: 200))
        if firstRange.location != NSNotFound {
            let string = NSMutableString(string: xmlString)
            string.insert("\n", at: firstRange.length)
            xmlString = String(string)
        }

        // 3) add a trailing newline if missing
        if let lastChar = xmlString.last, lastChar != "\n" {
            xmlString.append("\n")
        }

        guard let data = xmlString.data(using: .utf8) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        return data
        
        // Note: this (.nodePreserveCharacterReferences) does not work as expected..
        //        return xliffDocument.xmlData(options: [
        //            .nodePreserveCharacterReferences,
        //            ])

        //        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    private class func getXMLDocument(from data: Data) throws -> XMLDocument {
        do {
            return try XMLDocument(data: data, options: [
                .nodePreserveWhitespace,
                .nodeCompactEmptyElement,
                .nodePreserveCharacterReferences,
                ]
            )
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
        let controller = NSDocumentController.shared
        controller.currentDocument?.savePresentedItemChanges() { (error) in
        self.close()
            controller.reopenDocument(for: self.fileURL!, withContentsOf: self.fileURL!, display: true) { _,_,_ in }
        }
    }

}
