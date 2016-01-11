//
//  ViewController.swift
//  xliff-tool
//
//  Created by Remus Lazar on 06.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    // MARK: private data
    private var xliffFile: XliffFile? {
        didSet {
            updateStatusBar()
        }
    }
    
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
    
    // MARK: VC Lifecycle
    
    func reloadUI() {
        outlineView?.reloadData()
    }
    
    private func updateStatusBar() {
        if let file = xliffFile {
            infoLabel?.stringValue = String.localizedStringWithFormat(
                NSLocalizedString("%d file(s), %d localizable string(s) available", comment: "Status bar label"),
                file.files.count, file.totalCount)
        } else {
            infoLabel?.stringValue = NSLocalizedString("No xliff file loaded", comment: "Status bar label when no xliff file is loaded")
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadUI"),
            name: NSUndoManagerDidUndoChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadUI"),
            name: NSUndoManagerDidRedoChangeNotification, object: nil)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateTranslationForElement(elem: NSXMLElement, newValue: String) {
        
        if elem.elementsForName("target").count == 0 {
            elem.addChild(NSXMLElement(name: "target", stringValue: ""))
        }
        
        let target = elem.elementsForName("target").first!
        if newValue != target.stringValue {
            // register undo/redo operation
            document?.undoManager?.prepareWithInvocationTarget(self)
                .updateTranslationForElement(elem, newValue: target.stringValue!)
            
            // update the value in place
            target.stringValue = newValue
        }
        
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    @IBAction func textFieldEndEditing(sender: NSTextField) {
        let row = outlineView.rowForView(sender)
        if row != -1 {
            if let elem = outlineView.itemAtRow(row) as? NSXMLElement {
                updateTranslationForElement(elem, newValue: sender.stringValue)
            }
        }
    }
    
    @IBAction func filter(sender: NSSearchField) {
        print("filter: \(sender.stringValue)")
        if let xliffDocument = document?.xliffDocument {
            xliffFile = XliffFile(xliffDocument: xliffDocument, searchString: sender.stringValue.isEmpty ? nil : sender.stringValue)
            reloadUI()
            updateStatusBar()
            if !sender.stringValue.isEmpty {
                for item in xliffFile!.files {
                    outlineView?.expandItem(item)
                }
            }
        }
    }

    @IBOutlet weak var infoLabel: NSTextField! { didSet { updateStatusBar() } }
    
    // MARK: NSOutlineView Delegate
    
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
    
    private func configureContentCell(cell: NSTableCellView, columnIdentifier identifier: String, xmlElement: NSXMLElement) {
        switch identifier {
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
    
    private func heightForItem(item: AnyObject) -> CGFloat {
        let heights = outlineView.tableColumns.map { (col) -> CGFloat in
            let cell = outlineView.makeViewWithIdentifier(col.identifier, owner: nil) as! NSTableCellView
            let xmlElement = item as! NSXMLElement
            configureContentCell(cell, columnIdentifier: col.identifier, xmlElement: xmlElement)
            cell.layoutSubtreeIfNeeded()
            var width = cell.frame.size.width - 2 // leading space from the textField to the superView

            let row = outlineView.rowForItem(item)
            if (row == 0) {
                // because we're using NSOutliveView, the first level is indended by this amount
                let indent = outlineView.indentationPerLevel
                width += indent
            }
            
            let size = cell.textField!.sizeThatFits(CGSize(width: width, height: 10000))
            return size.height + 2 // some spacing between the table rows
        }
        return heights.maxElement()!
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let cell = outlineView.makeViewWithIdentifier(tableColumn == nil ? "GroupedItemCellIdentifier" : tableColumn!.identifier, owner: self) as! NSTableCellView
        
        // configure the cell
        if let file = item as? XliffFile.File {
            cell.textField!.stringValue = file.name
        } else if let xmlElement = item as? NSXMLElement {
            configureContentCell(cell, columnIdentifier: tableColumn!.identifier, xmlElement: xmlElement)
        }

        return cell
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return item is XliffFile.File
    }
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        if item is XliffFile.File { return outlineView.rowHeight }
        return heightForItem(item)
    }

}

