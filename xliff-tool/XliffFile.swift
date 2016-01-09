//
//  XliffFile.swift
//  xliff-tool
//
//  Created by Remus Lazar on 09.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Foundation

class XliffFile {

    class File {
        let name: String
        let items: [NSXMLElement]
        
        init(name: String, items: [NSXMLElement]) {
            self.name = name
            self.items = items
        }
    }
    
    private let xliff: NSXMLDocument
    let files: [File]
    
    init(xliffDocument: NSXMLDocument) {
        self.xliff = xliffDocument
        var files = [File]()
        
        if let root = xliffDocument.rootElement() {
            for file in root.children! {
                if let file = file as? NSXMLElement {
                    if file.name! == "file" {
                        files.append(File(name: file.attributeForName("original")!.stringValue!,
                            items: try! file.nodesForXPath("body/trans-unit") as! [NSXMLElement]))
                    }
                }
            }
        }
        
        self.files = files
    }
    
}
