Changes
=======

Version 1.0
-----------

v1.0b1

- Initial release

v1.0b2

- Cleanups, Upload to Mac App Store

v1.0b3

- Unit-Test Target added and a simple Unit-Test for the XLIFF Parsing algorithm
implemented
- App name changed to XLIFFTool

v1.0b4

- Bugfix: while working with multiple documents a table column resize operation
  affected all visible documents
- Performance: caching for table row heights implemented
- Feature: New option View > Compact Rows implemented, which is enabled by
default for bigger tables, for better usability and performance
- Bugfix: don't perform a reload table on all open documents after a undo/redo
operation

v1.0b5

- Hotfix, fixes some cases where the note table cell was not displayed correctly


Version 1.1
-----------

Build 6

- Reload File Feature (Cmd-R) implemented. This allows to re-iterate faster while using
  the Xcode "Editor > Export For Localization" and saving the file on the same
  location.

Build 7

- memory leak in the XliffFile class fixed


Version 1.2
-----------

Build 8

Bugfixes:

- Filter is now also using the source string

New Features:

- XLIFF XML file formatting and indending is now preserved
- New Filter option: "Show only non-translated items"
- FormatString Validation implemented: The validation logic checks if all format characters from source are also available in the target. If not, a ValidationError Window is modally presented, telling the user which format chars are missing.
- Better error handling and reporting when the XLIFF file cannot be parsed, also
  reporting the XPath where the first error occurred.
- Preserve the expanded-state of all the sections in the Outline View, especially when using the filter tool.

Build 9

- Fixes a crash on OS X 10.11.6 while opening the .xliff file within the app #17
- Refactoring for better performance while using the filter
- Fixes an exception on save #14
