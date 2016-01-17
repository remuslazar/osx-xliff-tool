//
//  ViewController.swift
//  xliff-tool
//
//  Created by Remus Lazar on 06.01.16.
//  Copyright © 2016 Remus Lazar. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    private struct Configuration {
        // max number of items in the XLIFF file to allow dynamic row height for all table rows
        // else we will re-tile just the selected row after selection, the remaining cells remaining single lined
        static let maxItemsForDynamicRowHeight = 150
    }

    // MARK: private data
    private var xliffFile: XliffFile? {
        didSet {
            updateStatusBar()
        }
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        if menuItem.action == Selector("toggleCompactRowsMode:") { // "Compact Rows" Setting
            // update the menu item state to match the current dynamicRowHeight setting
            if document == nil { return false }
            menuItem.state = dynamicRowHeight ? NSOffState : NSOnState
        }
        
        return true
    }
    
    private var dynamicRowHeight = false {
        didSet { reloadUI()}
    }
    
    weak var document: Document? {
        didSet {
            if let xliffDocument = document?.xliffDocument {
                xliffFile = XliffFile(xliffDocument: xliffDocument)
                if xliffFile?.totalCount < Configuration.maxItemsForDynamicRowHeight { dynamicRowHeight = true }
            } else {
                xliffFile = nil
            }
            outlineView.reloadData()
        }
    }
    
    
    // MARK: rowHeight Cache
    
    private var rowHeightsCache = [NSTableColumn: [NSXMLElement: CGFloat]]()

    private func purgeCachedHeightForItem(item: NSXMLElement) {
        for col in rowHeightsCache.keys {
            rowHeightsCache[col]!.removeValueForKey(item)
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
    
    func resizeTable(notification: NSNotification) {
        if let col = notification.userInfo?["NSTableColumn"] as? NSTableColumn {
            // invalidate cache for the specific row
            rowHeightsCache.removeValueForKey(col)
        }
        outlineView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(indexesInRange: NSRange(location: 0,length: outlineView.numberOfRows)))
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadUI"),
            name: NSUndoManagerDidUndoChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("reloadUI"),
            name: NSUndoManagerDidRedoChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("resizeTable:"),
            name: NSOutlineViewColumnDidResizeNotification, object: outlineView)
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
                purgeCachedHeightForItem(elem)
                outlineView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
            }
        }
    }
    
    @IBAction func filter(sender: NSSearchField) {
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

    @IBAction func toggleCompactRowsMode(sender: AnyObject) {
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = menuItem.state == NSOnState ? NSOffState : NSOnState
            dynamicRowHeight = menuItem.state == NSOffState
        }
    }
    
    @IBOutlet weak var infoLabel: NSTextField! { didSet { updateStatusBar() } }
    
    @IBOutlet weak var searchField: NSSearchField!
    
    // MARK: Menu actions
    @IBAction func deleteTranslationForSelectedRow(sender: AnyObject) {
        if outlineView.selectedRow != -1 {
            if let elem = outlineView.itemAtRow(outlineView.selectedRow) as? NSXMLElement {
                updateTranslationForElement(elem, newValue: "")
                outlineView.reloadDataForRowIndexes(NSIndexSet(index: outlineView.selectedRow),
                    columnIndexes: NSIndexSet(index: outlineView.columnWithIdentifier("AutomaticTableColumnIdentifier.1")))
            }
        }
    }
    
    /** Copy the source string to target for further editing. If no row is selected, this method does nothing */
    @IBAction func copySourceToTargetForSelectedRow(sender: AnyObject) {
        if outlineView.selectedRow != -1 {
            if let elem = outlineView.itemAtRow(outlineView.selectedRow) as? NSXMLElement,
                newValue = elem.elementsForName("source").first?.stringValue {
                updateTranslationForElement(elem, newValue: newValue )
                outlineView.reloadDataForRowIndexes(NSIndexSet(index: outlineView.selectedRow),
                    columnIndexes: NSIndexSet(index: outlineView.columnWithIdentifier("AutomaticTableColumnIdentifier.1")))
            }
        }
    }
    
    /** Activates the search/filter field in the UI so that the user can begin typing */
    @IBAction func activateSearchField(sender: AnyObject) {
        self.view.window?.makeFirstResponder(searchField)
    }
    
    // MARK: NSOutlineView Delegate and Datasource
    
    private var lastSelectedRow: Int?
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        if !dynamicRowHeight {
            // if not using the dynamicRowHeight behavior, resize the currently selected cell accordingly
            outlineView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: outlineView.selectedRow))
            if let last = lastSelectedRow {
                outlineView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: last))
            }
            lastSelectedRow = outlineView.selectedRow
        }
    }
    
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
    
    private func configureGroupCell(cell: NSTableCellView, file: XliffFile.File) {
        cell.textField!.stringValue = String.localizedStringWithFormat(
            NSLocalizedString("%@ (source=%@, target=%@)", comment: "Group header cell text, will show up in the outline view as a separator for each file in the XLIFF container."),
            file.name,
            file.sourceLanguage ?? NSLocalizedString("?", comment: "Placeholder telling the user that the source language for a specific file is unavailable in the source xliff file"),
            file.targetLanguage ?? NSLocalizedString("?", comment: "Placeholder telling the user that the target language for a specific file is unavailable in the source xliff file")
        )
    }
    
    
    private func heightForItem(item: AnyObject) -> CGFloat {
        let heights = outlineView.tableColumns.map { (col) -> CGFloat in
            let xmlElement = item as! NSXMLElement
            if let height = rowHeightsCache[col]?[xmlElement] { return height }
            
            let cell = outlineView.makeViewWithIdentifier(col.identifier, owner: nil) as! NSTableCellView
            
            configureContentCell(cell, columnIdentifier: col.identifier, xmlElement: xmlElement)
            let column = outlineView.columnWithIdentifier(col.identifier)
            var width = outlineView.tableColumns[column].width - 2

            let row = outlineView.rowForItem(item)
            if (row == 0) {
                // because we're using NSOutliveView, the first level is indended by this amount
                let indent = outlineView.indentationPerLevel
                width += indent
            }
           
            let size = cell.textField!.sizeThatFits(CGSize(width: width, height: 10000))
            let height = size.height + 2 // some spacing between the table rows
            
            if rowHeightsCache[col] != nil {
                rowHeightsCache[col]![xmlElement] = height
            } else {
                rowHeightsCache[col] = [xmlElement: height]
            }
            
            return height
        }
        return heights.maxElement()!
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let cell = outlineView.makeViewWithIdentifier(tableColumn == nil ? "GroupedItemCellIdentifier" : tableColumn!.identifier, owner: self) as! NSTableCellView
        
        // configure the cell
        if let file = item as? XliffFile.File {
            configureGroupCell(cell, file: file)
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
        if dynamicRowHeight {
            return heightForItem(item)
        } else {
            if let selectedItem = outlineView.itemAtRow(outlineView.selectedRow) {
                if item === selectedItem {
                    return heightForItem(item)
                }
            }
            return outlineView.rowHeight
        }
    }
    
}

