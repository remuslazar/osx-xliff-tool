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

    struct Filter {
        var searchString: String = ""
        var onlyNonTranslated = true
    }

    // TransUnit must be an @objc class because we're using it in the UndoManager
    @objc class TransUnit: NSObject {
        let id: String
        let source: String?
        var target: String? {
            didSet {
                // create the XML tag if needed
                if xmlElement.elements(forName: "target").count == 0 {
                    xmlElement.addChild(XMLElement(name: "target", stringValue: ""))
                }
                // update the value in the XML document as well
                let targetXMLElement = xmlElement.elements(forName: "target").first!
                targetXMLElement.stringValue = target
            }
        }
        let note: String?
        private let xmlElement: XMLElement
        
        init(xml: XMLElement) {
            xmlElement = xml
            self.id = xml.attribute(forName: "id")!.stringValue!
            self.source = xml.elements(forName: "source").first?.stringValue
            self.target = xml.elements(forName: "target").first?.stringValue
            self.note = xml.elements(forName: "note").first?.stringValue
        }
    }
    
    struct File: Hashable {
        let name: String
        let sourceLanguage: String?
        let targetLanguage: String?
        let items: [TransUnit]
        
        init(name: String, items: [TransUnit], sourceLanguage: String?, targetLanguage: String?) {
            self.name = name
            self.items = items
            self.sourceLanguage = sourceLanguage
            self.targetLanguage = targetLanguage
        }
        
        static func == (lhs: File, rhs: File) -> Bool {
            return lhs.name == rhs.name
        }
        
        var hashValue: Int {
            return self.name.hashValue
        }
        
    }
    
    private let xliff: XMLDocument

    /** Array of file containers available in the xliff container */
    let files: [File]
    
    init(xliffDocument: XMLDocument, filter: Filter = Filter()) {
        self.xliff = xliffDocument
        var files = [File]()
        if let root = xliffDocument.rootElement() {
            for file in root.elements(forName: "file") {
                var items = (try! file.nodes(forXPath: "body/trans-unit") as! [XMLElement])
                    .map { TransUnit(xml: $0) }
                
                if filter.onlyNonTranslated {
                    items = items.filter({
                        if let targetString = $0.target {
                            return targetString.isEmpty
                        }
                        return true
                    })
                }
                
                if !filter.searchString.isEmpty {
                    items = items.filter({
                        return ($0.source?.localizedCaseInsensitiveContains(filter.searchString) ?? true)
                            || ($0.target?.localizedCaseInsensitiveContains(filter.searchString) ?? true)
                            || ($0.note?.localizedCaseInsensitiveContains(filter.searchString) ?? true)
                    })
                }

                files.append(File(
                    name: file.attribute(forName: "original")!.stringValue!,
                    items: items,
                    sourceLanguage: file.attribute(forName: "source-language")?.stringValue,
                    targetLanguage: file.attribute(forName: "target-language")?.stringValue
                    ))
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
