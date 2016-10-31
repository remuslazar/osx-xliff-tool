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
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(ViewController.toggleCompactRowsMode(_:)) { // "Compact Rows" Setting
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
                if xliffFile != nil && xliffFile!.totalCount < Configuration.maxItemsForDynamicRowHeight { dynamicRowHeight = true }
            } else {
                xliffFile = nil
            }
            outlineView.reloadData()
        }
    }
    
    
    // MARK: rowHeight Cache
    
    private var rowHeightsCache = [NSTableColumn: [XMLElement: CGFloat]]()

    private func purgeCachedHeightForItem(_ item: XMLElement) {
        for col in rowHeightsCache.keys {
            rowHeightsCache[col]!.removeValue(forKey: item)
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
    
    func resizeTable(_ notification: Notification) {
        if let col = notification.userInfo?["NSTableColumn"] as? NSTableColumn {
            // invalidate cache for the specific row
            rowHeightsCache.removeValue(forKey: col)
        }
        outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: NSRange(location: 0,length: outlineView.numberOfRows).toRange() ?? 0..<0))
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadUI),
            name: NSNotification.Name.NSUndoManagerDidUndoChange, object: document!.undoManager)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reloadUI),
            name: NSNotification.Name.NSUndoManagerDidRedoChange, object: document!.undoManager)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.resizeTable(_:)),
            name: NSNotification.Name.NSOutlineViewColumnDidResize, object: outlineView)
    }
   
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateTranslationForElement(_ elem: XMLElement, newValue: String) {
        
        if elem.elements(forName: "target").count == 0 {
            elem.addChild(XMLElement(name: "target", stringValue: ""))
        }
        
        let target = elem.elements(forName: "target").first!
        if newValue != target.stringValue {
            // register undo/redo operation
            (document?.undoManager?.prepare(withInvocationTarget: self) as AnyObject)
                .updateTranslationForElement(elem, newValue: target.stringValue!)
            
            // update the value in place
            target.stringValue = newValue
        }
        
    }
    
    private var filter = XliffFile.Filter()
    
    private func reloadFilter() {
        if let xliffDocument = document?.xliffDocument {
            xliffFile = XliffFile(xliffDocument: xliffDocument, filter: filter)
            reloadUI()
            updateStatusBar()
            if !filter.searchString.isEmpty {
                for item in xliffFile!.files {
                    outlineView?.expandItem(item)
                }
            }
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    @IBAction func textFieldEndEditing(_ sender: NSTextField) {
        let row = outlineView.row(for: sender)
        if row != -1 {
            if let elem = outlineView.item(atRow: row) as? XMLElement {
                updateTranslationForElement(elem, newValue: sender.stringValue)
                purgeCachedHeightForItem(elem)
                outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
            }
        }
    }
    
    @IBAction func filter(_ sender: NSSearchField) {
        filter.searchString = sender.stringValue
        reloadFilter()
    }

    @IBAction func toggleCompactRowsMode(_ sender: AnyObject) {
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = menuItem.state == NSOnState ? NSOffState : NSOnState
            dynamicRowHeight = menuItem.state == NSOffState
        }
    }
    
    @IBOutlet weak var infoLabel: NSTextField! { didSet { updateStatusBar() } }
    
    @IBOutlet weak var searchField: NSSearchField!
    
    @IBOutlet weak var onlyNonTranslated: NSButton!
    
    @IBAction func toggleNonTranslatedFilterMode(_ sender: Any) {
        filter.onlyNonTranslated  = onlyNonTranslated.state == NSOnState
        reloadFilter()
    }
    
    // MARK: Menu actions
    @IBAction func deleteTranslationForSelectedRow(_ sender: AnyObject) {
        if outlineView.selectedRow != -1 {
            if let elem = outlineView.item(atRow: outlineView.selectedRow) as? XMLElement {
                updateTranslationForElement(elem, newValue: "")
                outlineView.reloadData(forRowIndexes: IndexSet(integer: outlineView.selectedRow),
                    columnIndexes: IndexSet(integer: outlineView.column(withIdentifier: "AutomaticTableColumnIdentifier.1")))
            }
        }
    }
    
    /** Copy the source string to target for further editing. If no row is selected, this method does nothing */
    @IBAction func copySourceToTargetForSelectedRow(_ sender: AnyObject) {
        if outlineView.selectedRow != -1 {
            if let elem = outlineView.item(atRow: outlineView.selectedRow) as? XMLElement,
                let newValue = elem.elements(forName: "source").first?.stringValue {
                updateTranslationForElement(elem, newValue: newValue )
                outlineView.reloadData(forRowIndexes: IndexSet(integer: outlineView.selectedRow),
                    columnIndexes: IndexSet(integer: outlineView.column(withIdentifier: "AutomaticTableColumnIdentifier.1")))
            }
        }
    }
    
    /** Activates the search/filter field in the UI so that the user can begin typing */
    @IBAction func activateSearchField(_ sender: AnyObject) {
        self.view.window?.makeFirstResponder(searchField)
    }
    
    // MARK: NSOutlineView Delegate and Datasource
    
    private var lastSelectedRow: Int?
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if !dynamicRowHeight {
            // if not using the dynamicRowHeight behavior, resize the currently selected cell accordingly
            outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: outlineView.selectedRow))
            if let last = lastSelectedRow {
                outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: last))
            }
            lastSelectedRow = outlineView.selectedRow
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil { // top level item
            return xliffFile != nil ? xliffFile!.files.count : 0
        } else {
            if let file = item as? XliffFile.File {
                return file.items.count
            }
        }
        
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // only top-level items are expandable
        return item is XliffFile.File
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil { // root item
            return xliffFile!.files[index]
        } else {
            let file = item as! XliffFile.File
            return file.items[index]
        }
    }
    
    private func configureContentCell(_ cell: NSTableCellView, columnIdentifier identifier: String, xmlElement: XMLElement) {
        switch identifier {
        case "AutomaticTableColumnIdentifier.0":
            cell.textField!.stringValue = xmlElement.elements(forName: "source").first?.stringValue ?? ""
            break
        case "AutomaticTableColumnIdentifier.1":
            cell.textField!.stringValue = xmlElement.elements(forName: "target").first?.stringValue ?? ""
            break
        case "AutomaticTableColumnIdentifier.2":
            cell.textField!.stringValue = xmlElement.elements(forName: "note").first?.stringValue ?? ""
            break
        default: break
        }
    }
    
    private func configureGroupCell(_ cell: NSTableCellView, file: XliffFile.File) {
        cell.textField!.stringValue = String.localizedStringWithFormat(
            NSLocalizedString("%@ (source=%@, target=%@)", comment: "Group header cell text, will show up in the outline view as a separator for each file in the XLIFF container."),
            file.name,
            file.sourceLanguage ?? NSLocalizedString("?", comment: "Placeholder telling the user that the source language for a specific file is unavailable in the source xliff file"),
            file.targetLanguage ?? NSLocalizedString("?", comment: "Placeholder telling the user that the target language for a specific file is unavailable in the source xliff file")
        )
    }
    
    
    private func heightForItem(_ item: AnyObject) -> CGFloat {
        let heights = outlineView.tableColumns.map { (col) -> CGFloat in
            let xmlElement = item as! XMLElement
            if let height = rowHeightsCache[col]?[xmlElement] { return height }
            
            let cell = outlineView.make(withIdentifier: col.identifier, owner: nil) as! NSTableCellView
            
            configureContentCell(cell, columnIdentifier: col.identifier, xmlElement: xmlElement)
            cell.layoutSubtreeIfNeeded()
            let column = outlineView.column(withIdentifier: col.identifier)
            var width = outlineView.tableColumns[column].width
            
            if (col.identifier == "AutomaticTableColumnIdentifier.0") {
                // because we're using NSOutliveView, the first level is indended by this amount
                width -= outlineView.indentationPerLevel + 14.0
            }
           
            let size = cell.textField!.sizeThatFits(CGSize(width: width, height: 10000))
            let height = size.height + 2.0 // some spacing between the table rows
            
            if rowHeightsCache[col] != nil {
                rowHeightsCache[col]![xmlElement] = height
            } else {
                rowHeightsCache[col] = [xmlElement: height]
            }
            
            return height
        }
        return heights.max()!
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineView.make(withIdentifier: tableColumn == nil ? "GroupedItemCellIdentifier" : tableColumn!.identifier, owner: self) as! NSTableCellView
        
        // configure the cell
        if let file = item as? XliffFile.File {
            configureGroupCell(cell, file: file)
        } else if let xmlElement = item as? XMLElement {
            configureContentCell(cell, columnIdentifier: tableColumn!.identifier, xmlElement: xmlElement)
        }

        return cell
    }
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return item is XliffFile.File
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is XliffFile.File { return outlineView.rowHeight }
        if dynamicRowHeight {
            return heightForItem(item as AnyObject)
        } else if let item = item as? XMLElement, let selectedItem = outlineView.item(atRow: outlineView.selectedRow) as? XMLElement {
            if item === selectedItem {
                return heightForItem(item as AnyObject)
            }
        }
        return outlineView.rowHeight
    }
    
}

