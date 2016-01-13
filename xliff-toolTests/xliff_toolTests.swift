//
//  xliff_toolTests.swift
//  xliff-toolTests
//
//  Created by Remus Lazar on 13.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import XCTest

class xliff_toolTests: XCTestCase {
    
    var testBundle: NSBundle!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testBundle = NSBundle(forClass: self.dynamicType)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testXliffParsing() {
        // get the URL of the XML test file
        let url = testBundle.URLForResource("de", withExtension: "xliff")!
        let xliffData = NSData(contentsOfURL: url)!
        let document = try! NSXMLDocument(data: xliffData, options: NSXMLDocumentTidyHTML)
        let xliffFile = XliffFile(xliffDocument: document)
        
        XCTAssertEqual(xliffFile.files.count, 4)
        XCTAssertEqual(xliffFile.totalCount, 70)
        
        XCTAssertEqual(xliffFile.files[0].sourceLanguage!, "en")
        XCTAssertEqual(xliffFile.files[0].targetLanguage!, "de")

        XCTAssertEqual(xliffFile.files[0].items.first!.elementsForName("source").first!.stringValue, "Text Cell")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
