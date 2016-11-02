//
//  xliff_toolTests.swift
//  xliff-toolTests
//
//  Created by Remus Lazar on 13.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import XCTest
@testable import XLIFFTool

extension String {
    var lines:[String] {
        var result:[String] = []
        enumerateLines{ (line, _) in result.append(line) }
        return result
    }
}

class xliff_toolTests: XCTestCase {
    
    var testBundle: Bundle!
    var document: Document!
    
    var xliffData: Data!
    var xliffFile: XliffFile!
    var xliffDocument: XMLDocument!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        testBundle = Bundle(for: type(of: self))
        document = try! Document(type: "XLIFF Localization File")
        let url = testBundle.url(forResource: "de", withExtension: "xliff")!
        xliffData = try! Data(contentsOf: url)
        
        try! document.read(from: url, ofType: "")
        xliffDocument = document.xliffDocument
        xliffFile = try! XliffFile(xliffDocument: xliffDocument, filter: nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testXliffParsing() {
        // get the URL of the XML test file
        
        XCTAssertEqual(xliffFile.files.count, 4)
        XCTAssertEqual(xliffFile.totalCount, 70)
        
        XCTAssertEqual(xliffFile.files[0].sourceLanguage!, "en")
        XCTAssertEqual(xliffFile.files[0].targetLanguage!, "de")

        XCTAssertEqual(xliffFile.files[0].items.first!.source, "Text Cell")
    }
    
    // check if the saved XML XLIFF file is valid XML
    func testXliffValidAfterSave() {
        let data = xliffDocument.xmlData
        let document = try! Document(type: "XLIFF Localization File")
        do {
            let _ = try document.read(from: data, ofType: "")
        } catch {
            print (error.localizedDescription)
            XCTFail()
        }
    }
    
    // check of the xml file is saved while preserving all whitespace/line breaks from the original
    func testSaveFormatting() {
        let data = xliffDocument.xmlData
        if let content = String(data: data, encoding: .utf8),
            let originalContent = String(data: xliffData, encoding: .utf8) {
            // check if the 3. last line is equal
            XCTAssertEqual(
                content.lines[content.lines.count - 3],
                originalContent.lines[originalContent.lines.count - 3] )
        }
    }
    
    func testParsingPerformance() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            let url = self.testBundle.url(forResource: "bigfile", withExtension: "xliff")!
            do {
                try self.document.read(from: url, ofType: "")
            } catch {
                print(error)
                XCTFail()
            }
        }
    }
    
}
