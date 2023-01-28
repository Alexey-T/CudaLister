Lister plugin for Total Commander.
it is viewer/editor for source codes, it shows them with syntax highlighting.

usage
=====
you can click statusbar lexer-field, to change active lexer.
you can click statusbar encoding-field, to change it.
you can edit current file, by unchecking "Read-only" in the context menu.
you can save changed file on closing, or by "Save" item in the context menu.

hotkeys:
- Ctrl+Z - undo
- Ctrl+Shift+Z - redo
- Ctrl+U - convert to upper case
- Ctrl+Shift+U - convert to lower case
- Ctrl+G - call 'go to' dialog
- Ctrl+R - toggle read/only mode
- Ctrl+S - save modified file
- Ctrl+W - toggle word-wrap
- Ctrl+F - call 'find' dialog
- F3 - find next
- Shift+F3 - find previous

lexers
======
in the "lexers" dir, many lexers are available.
you can unpack to this dir more lexers from CudaText:
http://sourceforge.net/projects/synwrite-addons/files/Lexers/

themes
======
theme files from CudaText are used.
you can find more on http://cudatext.sf.net
documentation: http://wiki.freepascal.org/CudaText#Color_themes

code
====
plugin is written in Lazarus 2.2.
plugin source code: 
https://github.com/alexey-t/cudalister
uses packages: ATSynEdit, ATSynEdit_Ex, ATFlatControls, EControl, all here:
https://github.com/alexey-t/

author: Alexey Torgashin (CudaText)
initial help by: Andrey Gunenko
license: MPL 2.0
