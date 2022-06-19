# Lister plugin for Total Commander

this is a viewer/editor for source code that features syntax highlighting and theming.

- you can click the statusbar lexer field to change the active lexer.
- you can click the statusbar encoding field to change it.
- you can edit the current file by unchecking "Read-only" in the context menu.
- you can save the modified file at close-time or by using "Save" in the context menu.

lexers
======

in the "lexers" folder, many lexers are available.

you can add more lexers [from CudaText](http://sourceforge.net/projects/synwrite-addons/files/Lexers/) by unpacking them into it.

themes
======

theme files from CudaText are used.

you can find more on http://cudatext.sf.net

documentation: http://wiki.freepascal.org/CudaText#Color_themes

code
====

this plugin is written in Lazarus 2.2.

it uses the packages `ATFlatControls`, `ATSynEdit`, `ATSynEdit_Ex`, `EControl`, all available [here](https://github.com/alexey-t/).

authors
=======
  
- Alexey Torgashin (CudaText)
- initial help by Andrey Gunenko

*license: MPL 2.0*
