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
        let items: [XMLElement]
        
        init(name: String, items: [XMLElement], sourceLanguage: String?, targetLanguage: String?) {
            self.name = name
            self.items = items
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
        }
    }
    
    private let xliff: XMLDocument

    /** Array of file containers available in the xliff container */
    let files: [File]
    
    init(xliffDocument: XMLDocument, searchString: String? = nil) {
        self.xliff = xliffDocument
        var files = [File]()
        if let root = xliffDocument.rootElement() {
            for file in root.elements(forName: "file") {
                var items = try! file.nodes(forXPath: "body/trans-unit") as! [XMLElement]
                if let search = searchString {
                    items = items.filter({ (elem) -> Bool in
                        for elementName in ["original", "target", "note"] {
                            if let s = elem.elements(forName: elementName).first?.stringValue {
                                if s.localizedCaseInsensitiveContains(search) { return true }
                            }
                        }
                        return false
                    })
                }
                files.append(File(
                    name: file.attribute(forName: "original")!.stringValue!,
                    items: items.map { return $0 }, // dont use the items array directly to avoid memory leaks
                    sourceLanguage: file.attribute(forName: "source-language")?.stringValue,
                    targetLanguage: file.attribute(forName: "target-language")?.stringValue))
            }
        }
        
        self.files = files
    }
    
    var totalCount: Int {
        return files.map({ (file) -> Int in
            return file.items.count
        }).reduce(0, +)
    }
    
}
