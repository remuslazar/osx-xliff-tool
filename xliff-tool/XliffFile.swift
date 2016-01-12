//
//  XliffFile.swift
//  xliff-tool
//
//  Created by Remus Lazar on 09.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Foundation

/**
 Parses the XLIFF document and provides some convenience methods (e.g. for calculating total count).
 Useful to "front" a XLIFF document implementing the TableView delegate methods.
 */
class XliffFile {

    class File {
        let name: String
        let sourceLanguage: String?
        let targetLanguage: String?
        let items: [NSXMLElement]
        
        init(name: String, items: [NSXMLElement], sourceLanguage: String?, targetLanguage: String?) {
            self.name = name
            self.items = items
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
        }
    }
    
    private let xliff: NSXMLDocument

    /** Array of file containers available in the xliff container */
    let files: [File]
    
    init(xliffDocument: NSXMLDocument, searchString: String? = nil) {
        self.xliff = xliffDocument
        var files = [File]()
        if let root = xliffDocument.rootElement() {
            for file in root.elementsForName("file") {
                var items = try! file.nodesForXPath("body/trans-unit") as! [NSXMLElement]
                if let search = searchString {
                    items = items.filter({ (elem) -> Bool in
                        for elementName in ["original", "target", "note"] {
                            if let s = elem.elementsForName(elementName).first?.stringValue {
                                if s.localizedCaseInsensitiveContainsString(search) { return true }
                            }
                        }
                        return false
                    })
                }
                files.append(File(
                    name: file.attributeForName("original")!.stringValue!,
                    items: items,
                    sourceLanguage: file.attributeForName("source-language")?.stringValue,
                    targetLanguage: file.attributeForName("target-language")?.stringValue))
            }
        }
        
        self.files = files
    }
    
    var totalCount: Int {
        return files.map({ (file) -> Int in
            return file.items.count
        }).reduce(0, combine: +)
    }
    
}
