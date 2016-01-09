//
//  ViewController.swift
//  xliff-tool
//
//  Created by Remus Lazar on 06.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    var xliffFile: XliffFile?
    
    weak var document: Document? {
        didSet {
            if let xliffDocument = document?.xliffDocument {
                xliffFile = XliffFile(xliffDocument: xliffDocument)
            } else {
                xliffFile = nil
            }
            outlineView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var representedObject: AnyObject? {
        didSet {
            print("representedObject: \(self.representedObject)")
        // Update the view, if already loaded.
        }
    }
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil { // top level item
            return xliffFile != nil ? xliffFile!.files.count : 0
        } else {
            if let file = item as? XliffFile.File {
                return file.items.count
            }
        }
        
        return 0
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        // only top-level items are expandable
        return item is XliffFile.File
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil { // root item
            return xliffFile!.files[index]
        } else {
            let file = item as! XliffFile.File
            return file.items[index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let cell = outlineView.makeViewWithIdentifier(tableColumn == nil ? "GroupedItemCellIdentifier" : tableColumn!.identifier, owner: nil) as! NSTableCellView
        
        // configure the cell
        if let file = item as? XliffFile.File {
            cell.textField!.stringValue = file.name
        } else if let xmlElement = item as? NSXMLElement {
            switch tableColumn!.identifier {
            case "AutomaticTableColumnIdentifier.0":
                cell.textField!.stringValue = xmlElement.elementsForName("source").first?.stringValue ?? ""
                break
            case "AutomaticTableColumnIdentifier.1":
                cell.textField!.stringValue = xmlElement.elementsForName("target").first?.stringValue ?? ""
                break
            case "AutomaticTableColumnIdentifier.2":
                cell.textField!.stringValue = xmlElement.elementsForName("note").first?.stringValue ?? ""
                break
            default: break
            }
        }
        
        return cell
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return item is XliffFile.File
    }
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        if item is XliffFile.File { return outlineView.rowHeight }
        return 75.0
    }

}

