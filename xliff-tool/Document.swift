//
//  Document.swift
//  xliff-tool
//
//  Created by Remus Lazar on 06.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class Document: NSDocument {

    var xliffDocument: NSXMLDocument!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    override func dataOfType(typeName: String) throws -> NSData {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        return xliffDocument.XMLData
//        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        do {
            self.xliffDocument = try NSXMLDocument(data: data, options: NSXMLDocumentTidyHTML)
        } catch (let error as NSError) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadCorruptFileError, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Could not read file.", comment: "Read error description"),
                NSLocalizedFailureReasonErrorKey: error.localizedDescription ??
                    NSLocalizedString("File was in an invalid format.", comment: "Read failure reason")
                ])
        }
        
    }
    
    @IBAction func reloadDocument(sender: AnyObject?) {
        let controller = NSDocumentController.sharedDocumentController()
        controller.currentDocument?.savePresentedItemChangesWithCompletionHandler() { (error) in
        self.close()
            controller.reopenDocumentForURL(self.fileURL!, withContentsOfURL: self.fileURL!, display: true) { _,_,_ in }
        }
    }

    var fileLastModificationDate: NSDate?
    
    private func getFileLastModificationDate(completionHandler: (NSDate) -> Void) {
        if let url = fileURL {
            let coordinator = NSFileCoordinator(filePresenter: self)
            coordinator.coordinateReadingItemAtURL(url, options: .ImmediatelyAvailableMetadataOnly, error: nil) { (url) in
                var lastMod: AnyObject?
                try! url.getResourceValue(&lastMod, forKey: NSURLContentModificationDateKey)
                completionHandler(lastMod as! NSDate)
            }
        }
    }

    // while reading and saving the file we read the file last modification timestamp,
    // so we can detect the case when the file was overwritten externally
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        try super.readFromURL(url, ofType: typeName)
        self.getFileLastModificationDate() { self.fileLastModificationDate = $0 }
    }
    
    override func saveToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, completionHandler: (NSError?) -> Void) {
        super.saveToURL(url, ofType: typeName, forSaveOperation: saveOperation) { (error) -> Void in
            completionHandler(error)
            self.getFileLastModificationDate() { self.fileLastModificationDate = $0 }
        }
    }

    private func popupReloadFileAlert() {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = NSAlert()
            alert.informativeText = NSLocalizedString("Source file was changed and there are unsaved changes in memory.",
                comment: "Alert Dialog message telling the user that the source file was changed externally and presents him the options")
            alert.messageText = NSLocalizedString("Source file changed on disk",
                comment: "Alert Title telling the user that the file has been changed")
            
            // buttons
            alert.addButtonWithTitle(NSLocalizedString("Ignore", comment: "Option to ignore it"))
            alert.addButtonWithTitle(NSLocalizedString("Reload file", comment: "Option to reload the file"))
            
            alert.alertStyle = .CriticalAlertStyle
            
            if alert.runModal() == NSAlertFirstButtonReturn { // overwrite source file
            } else { // reload file
                print("reloading..")
                self.reloadDocument(nil)
            }
        }
    }
    
    override func presentedItemDidChange() {
        super.presentedItemDidChange()
        getFileLastModificationDate() {
            let interval = $0.timeIntervalSinceDate(self.fileLastModificationDate!)
            if interval > 0 {
                print("source file was changed externally")
                self.popupReloadFileAlert()
            }
        }
    }
    
}

