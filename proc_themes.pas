unit proc_themes;

{$mode objfpc}{$H+}
//this unit is mostly copy-paste from CudaText

interface

uses
  Classes, SysUtils, Graphics,
  Dialogs,
  IniFiles,
  file_proc,
  jsonConf,
  ec_SyntAnal,
  ec_syntax_format,
  ATStringProc,
  ATStringProc_HtmlColor,
  ATSynEdit;

type
  TAppColor = record
    color: TColor;
    name, desc: string;
  end;
  TAppTheme = record
    Colors: array of TAppColor;
    Styles: TStringList;
  end;

var
  AppTheme: TAppTheme;

procedure DoInitTheme(var D: TAppTheme);
procedure DoLoadTheme(const fn: string; var D: TAppTheme; IsThemeUI: boolean);

function GetAppColor(const AName: string): TColor;
function GetAppStyleFromName(const SName: string): TecSyntaxFormat;

procedure DoApplyEditorTheme(Ed: TATSynedit);
function DoApplyLexerStylesMap(an: TecSyntAnalyzer): boolean;


implementation

function FontStylesToString(const f: TFontStyles): string;
begin
  Result:= '';
  if fsBold in f then Result:= Result+'b';
  if fsItalic in f then Result:= Result+'i';
  if fsUnderline in f then Result:= Result+'u';
  if fsStrikeout in f then Result:= Result+'s';
end;

function StringToFontStyles(const s: string): TFontStyles;
var
  i: Integer;
begin
  Result:= [];
  for i:= 1 to Length(s) do
    case s[i] of
      'b': Include(Result, fsBold);
      'i': Include(Result, fsItalic);
      'u': Include(Result, fsUnderline);
      's': Include(Result, fsStrikeout);
    end;
end;

function GetAppColor(const AName: string): TColor;
var
  i: integer;
begin
  Result:= clRed;
  for i:= Low(AppTheme.Colors) to High(AppTheme.Colors) do
    if AppTheme.Colors[i].name=AName then
      exit(AppTheme.Colors[i].color);
  //raise Exception.Create('Incorrect color id: '+name);
end;

function GetAppStyleFromName(const SName: string): TecSyntaxFormat;
var
  N: integer;
begin
  Result:= nil;
  if SName='' then exit;
  if AppTheme.Styles.Find(SName, N) then
    exit(TecSyntaxFormat(AppTheme.Styles.Objects[N]));
end;


procedure DoLoadLexerStyleFromFile(st: TecSyntaxFormat; cfg: TJSONConfig;
  skey: string);
var
  Len: integer;
  n: integer;
  s: string;
begin
  if not SEndsWith(skey, '/') then skey:= skey+'/';

  n:= cfg.GetValue(skey+'Type', Ord(st.FormatType));
  st.FormatType:= TecFormatType(n);

  s:= cfg.GetValue(skey+'Styles', FontStylesToString(st.Font.Style));
  st.Font.Style:= StringToFontStyles(s);

  s:= cfg.GetValue(skey+'CFont', '');
  n:= TATHtmlColorParserA.ParseTokenRGB(PChar(s), Len, st.Font.Color);
  st.Font.Color:= n;

  s:= cfg.GetValue(skey+'CBack', '');
  n:= TATHtmlColorParserA.ParseTokenRGB(PChar(s), Len, st.BgColor);
  st.BgColor:= n;

  s:= cfg.GetValue(skey+'CBorder', '');
  st.BorderColorBottom:= TATHtmlColorParserA.ParseTokenRGB(PChar(s), Len, st.BorderColorBottom);
  st.BorderColorLeft:= st.BorderColorBottom;
  st.BorderColorRight:= st.BorderColorBottom;
  st.BorderColorTop:= st.BorderColorBottom;

  s:= cfg.GetValue(skey+'Border', '');
  if s<>'' then
  begin
    st.BorderTypeLeft:= TecBorderLineType(StrToIntDef(SGetItem(s), 0));
    st.BorderTypeRight:= TecBorderLineType(StrToIntDef(SGetItem(s), 0));
    st.BorderTypeTop:= TecBorderLineType(StrToIntDef(SGetItem(s), 0));
    st.BorderTypeBottom:= TecBorderLineType(StrToIntDef(SGetItem(s), 0));
  end;
end;


procedure DoLoadTheme(const fn: string; var D: TAppTheme; IsThemeUI: boolean);
var
  c: TJsonConfig;
  //
  procedure DoVal(var Val: TColor; const id: string);
  var
    s: string;
    len: integer;
  begin
    s:= c.GetValue(id, '?');
    if s='?' then exit;
    if s='' then
      Val:= clNone
    else
      Val:= TATHtmlColorParserA.ParseTokenRGB(PChar(s), len, Val);
  end;
  //
var
  sName: string;
  st: TecSyntaxFormat;
  i: integer;
begin
  c:= TJsonConfig.Create(nil);
  try
    try
      c.Filename:= fn;
    except
      Showmessage('Cannot read JSON theme'+#13+fn);
      Exit
    end;

    if IsThemeUI then
    begin
      for i:= Low(D.Colors) to High(D.Colors) do
        DoVal(D.Colors[i].color, D.Colors[i].name);
    end
    else
    begin
      for i:= 0 to d.Styles.Count-1 do
      begin
        sName:= d.Styles[i];
        st:= TecSyntaxFormat(d.Styles.Objects[i]);
        DoLoadLexerStyleFromFile(st, c, 'Lex_'+sName);
      end;
    end;
  finally
    c.Free;
  end;
end;

procedure DoInitTheme(var D: TAppTheme);
  //
  procedure Add(color: TColor; const name, desc: string);
  begin
    SetLength(D.Colors, Length(D.Colors)+1);
    D.Colors[High(D.Colors)].color:= color;
    D.Colors[High(D.Colors)].name:= name;
    D.Colors[High(D.Colors)].desc:= desc;
  end;
  //
  procedure AddStyle(const SName: string;
    NColorFont, NColorBg, NColorBorder: TColor;
    NFontStyle: TFontStyles;
    NBorderLeft, NBorderRight, NBorderUp, NBorderDown: TecBorderLineType;
    NFormatType: TecFormatType);
  var
    st: TecSyntaxFormat;
  begin
    st:= TecSyntaxFormat.Create(nil);
    st.DisplayName:= SName;
    st.Font.Color:= NColorFont;
    st.Font.Style:= NFontStyle;
    st.BgColor:= NColorBg;
    st.BorderColorLeft:= NColorBorder;
    st.BorderColorRight:= NColorBorder;
    st.BorderColorTop:= NColorBorder;
    st.BorderColorBottom:= NColorBorder;
    st.BorderTypeLeft:= NBorderLeft;
    st.BorderTypeRight:= NBorderRight;
    st.BorderTypeTop:= NBorderUp;
    st.BorderTypeBottom:= NBorderDown;
    st.FormatType:= NFormatType;

    D.Styles.AddObject(SName, st);
  end;
  //
const
  nColorText = $202020;
  nColorBack = $e4e4e4;
  nColorBack2 = $c8c8c8;
  nColorGutterBack = $d8d8d8;
  nColorGutterFont = $909090;
  nColorArrow = $969696;
  nColorBorder = $c0c0c0;
  nColorListBack = $d0d0d0;
  nColorListSelBack = $c0c0c0;
begin
  SetLength(D.Colors, 0);

  if Assigned(D.Styles) then
    D.Styles.Clear
  else
  begin
    D.Styles:= TStringList.Create;
    D.Styles.Sorted:= true;
    D.Styles.OwnsObjects:= true;
  end;

  //add colors
  Add(nColorText, 'EdTextFont', 'editor, font');
  Add(nColorBack, 'EdTextBg', 'editor, BG');
  Add($e0e0e0, 'EdSelFont', 'editor, selection, font');
  Add($b0a0a0, 'EdSelBg', 'editor, selection, BG');
  Add(clGray, 'EdDisableFont', 'editor, disabled state, font');
  Add(nColorGutterBack, 'EdDisableBg', 'editor, disabled state, BG');
  Add($c05050, 'EdLinks', 'editor, links');
  Add(nColorGutterBack, 'EdLockedBg', 'editor, locked state, BG');
  Add(clBlack, 'EdCaret', 'editor, caret');
  Add($6060d0, 'EdMarkers', 'editor, markers');
  Add($eaf0f0, 'EdCurLineBg', 'editor, current line BG');
  Add(clMedGray, 'EdIndentVLine', 'editor, wrapped line indent vert-lines');
  Add($a0a0b8, 'EdUnprintFont', 'editor, unprinted chars, font');
  Add($e0e0e0, 'EdUnprintBg', 'editor, unprinted chars, BG');
  Add(clMedGray, 'EdUnprintHexFont', 'editor, special hex codes, font');
  Add(clLtGray, 'EdMinimapBorder', 'editor, minimap, border');
  Add($eeeeee, 'EdMinimapSelBg', 'editor, minimap, view BG');
  Add(clMoneyGreen, 'EdMinimapTooltipBg', 'editor, minimap, tooltip BG');
  Add(clMedGray, 'EdMinimapTooltipBorder', 'editor, minimap, tooltip border');
  Add($e0e0e0, 'EdMicromapBg', 'editor, micromap, BG');
  Add($c0c0c0, 'EdMicromapViewBg', 'editor, micromap, current view area');
  Add($c05050, 'EdMicromapOccur', 'editor, micromap, word occurrences');
  Add($6060d0, 'EdMicromapSpell', 'editor, micromap, misspelled marks');
  Add($70b0b0, 'EdStateChanged', 'editor, line states, changed');
  Add($80a080, 'EdStateAdded', 'editor, line states, added');
  Add(clMedGray, 'EdStateSaved', 'editor, line states, saved');
  Add($b0b0b0, 'EdBlockStaple', 'editor, block staples (indent guides)');
  Add(nColorArrow, 'EdComboArrow', 'editor, combobox arrow-down');
  Add(nColorBack, 'EdComboArrowBg', 'editor, combobox arrow-down BG');
  Add(nColorBorder, 'EdBorder', 'editor, combobox border');
  Add(clNavy, 'EdBorderFocused', 'editor, combobox border, focused');
  Add(clMedGray, 'EdBlockSepLine', 'editor, separator line');
  Add($a06060, 'EdFoldMarkLine', 'editor, folded line');
  Add($e08080, 'EdFoldMarkFont', 'editor, folded block mark, font');
  Add($e08080, 'EdFoldMarkBorder', 'editor, folded block mark, border');
  Add(nColorBack, 'EdFoldMarkBg', 'editor, folded block mark, BG');
  Add(nColorGutterFont, 'EdGutterFont', 'editor, gutter font');
  Add(nColorGutterBack, 'EdGutterBg', 'editor, gutter BG');
  Add(nColorGutterFont, 'EdGutterCaretFont', 'editor, gutter font, lines with carets');
  Add(nColorListSelBack, 'EdGutterCaretBg', 'editor, gutter BG, lines with carets');
  Add(nColorGutterFont, 'EdRulerFont', 'editor, ruler font');
  Add(nColorBack, 'EdRulerBg', 'editor, ruler BG');
  Add(nColorGutterFont, 'EdFoldLine', 'editor, gutter folding, lines');
  Add(nColorGutterFont, 'EdFoldLine2', 'editor, gutter folding, lines, current range');
  Add(nColorGutterBack, 'EdFoldBg', 'editor, gutter folding, BG');
  Add(nColorGutterFont, 'EdFoldPlusLine', 'editor, gutter folding, "plus" border');
  Add(nColorGutterBack, 'EdFoldPlusBg', 'editor, gutter folding, "plus" BG');
  Add(clLtGray, 'EdMarginFixed', 'editor, margin, fixed position');
  Add($b0c0c0, 'EdMarginCaret', 'editor, margins, for carets');
  Add($b0c0c0, 'EdMarginUser', 'editor, margins, user defined');
  Add(clMoneyGreen, 'EdBookmarkBg', 'editor, bookmark, line BG');
  Add(clMedGray, 'EdBookmarkIcon', 'editor, bookmark, gutter mark');
  Add($f0e0b0, 'EdMarkedRangeBg', 'editor, marked range BG');

  Add(nColorBack2, 'TabBg', 'main-toolbar, tabs BG');
  Add($808080, 'SideBg', 'side-toolbar BG');
  Add(nColorText, 'TabFont', 'tabs, font');
  Add($a00000, 'TabFontMod', 'tabs, font, modified tab');
  Add(nColorBack, 'TabActive', 'tabs, active tab BG');
  Add($e4d0d0, 'TabActiveOthers', 'tabs, active tab BG, inactive groups');
  Add(nColorBack2+$0a0a0a, 'TabPassive', 'tabs, passive tab BG');
  Add($ffffff, 'TabOver', 'tabs, mouse-over tab BG');
  Add(nColorBorder, 'TabBorderActive', 'tabs, active tab border');
  Add(nColorBorder, 'TabBorderPassive', 'tabs, passive tab border');
  Add(clNone, 'TabCloseBg', 'tabs, close button BG');
  Add($9090c0, 'TabCloseBgOver', 'tabs, close button BG, mouse-over');
  Add($9090c0, 'TabCloseBorderOver', 'tabs, close button border');
  Add(nColorArrow, 'TabCloseX', 'tabs, close x mark');
  Add(nColorBack, 'TabCloseXOver', 'tabs, close x mark, mouse-over');
  Add(nColorArrow, 'TabArrow', 'tabs, triangle arrows');
  Add($404040, 'TabArrowOver', 'tabs, triangle arrows, mouse-over');
  Add(clMedGray, 'TabActiveMark', 'tabs, flat style, active tab mark');
  Add($6060E0, 'TabMarks', 'tabs, special marks');

  Add(nColorText, 'TreeFont', 'treeview, font');
  Add(nColorBack, 'TreeBg', 'treeview, BG');
  Add(nColorText, 'TreeSelFont', 'treeview, selected font');
  Add(nColorListSelBack, 'TreeSelBg', 'treeview, selected BG');
  Add(nColorGutterFont, 'TreeLines', 'treeview, lines');
  Add(nColorGutterFont, 'TreeSign', 'treeview, fold sign');

  Add(nColorListBack, 'ListBg', 'listbox, BG');
  Add(nColorListSelBack, 'ListSelBg', 'listbox, selected line BG');
  Add(nColorText, 'ListFont', 'listbox, font');
  Add(nColorText, 'ListSelFont', 'listbox, selected line font');
  Add($c05050, 'ListFontHotkey', 'listbox, font, hotkey');
  Add($e00000, 'ListFontHilite', 'listbox, font, search chars');

  Add($c05050, 'ListCompletePrefix', 'listbox, font, auto-complete prefix');
  Add(clGray, 'ListCompleteParams', 'listbox, font, auto-complete params');

  Add($a0a0a0, 'GaugeFill', 'search progressbar, fill');
  Add($e0e0e0, 'GaugeBg', 'search progressbar, BG');

  Add(nColorText, 'ButtonFont', 'buttons, font');
  Add($808088, 'ButtonFontDisabled', 'buttons, font, disabled state');
  Add(nColorBack, 'ButtonBgPassive', 'buttons, BG, passive');
  Add($d0b0b0, 'ButtonBgOver', 'buttons, BG, mouse-over');
  Add($b0b0b0, 'ButtonBgChecked', 'buttons, BG, checked state');
  Add($c0c0d0, 'ButtonBgDisabled', 'buttons, BG, disabled state');
  Add(nColorBorder, 'ButtonBorderPassive', 'buttons, border, passive');
  Add(nColorBorder, 'ButtonBorderOver', 'buttons, border, mouse-over');
  Add(clGray, 'ButtonBorderFocused', 'buttons, border, focused');

  Add(nColorGutterBack, 'ScrollBack', 'scrollbar, BG');
  Add(nColorBorder, 'ScrollRect', 'scrollbar, thumb border');
  Add(nColorBack, 'ScrollFill', 'scrollbar, thumb fill');
  Add(nColorArrow, 'ScrollArrow', 'scrollbar, arrow');
  Add($d0d0d0, 'ScrollScrolled', 'scrollbar, scrolling area');

  Add(nColorText, 'StatusFont', 'statusbar, font');
  Add(nColorBack2, 'StatusBg', 'statusbar, BG');
  Add(nColorBorder, 'StatusLines', 'statusbar, border');
  Add(nColorText, 'StatusAltFont', 'statusbar alternative, font');
  Add(clCream, 'StatusAltBg', 'statusbar alternative, BG');

  Add(nColorBack2, 'SplitMain', 'splitters, main');
  Add(nColorBack2, 'SplitGroups', 'splitters, groups');

  Add(clWhite, 'ExportHtmlBg', 'export to html, BG');
  Add(clMedGray, 'ExportHtmlNumbers', 'export to html, line numbers');

  //--------------
  //add styles
  AddStyle('Id', nColorText, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Id1', clNavy, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Id2', clPurple, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Id3', clOlive, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Id4', clBlue, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('IdKeyword', clBlack, clNone, clNone, [fsBold], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('IdVar', clGreen, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('IdBad', clBlack, clNone, clRed, [], blNone, blNone, blNone, blSolid, ftFontAttr);

  AddStyle('String', clTeal, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('String2', clOlive, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('String3', $C8C040, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);

  AddStyle('Symbol', clMaroon, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Symbol2', $0000C0, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('SymbolBad', clMaroon, clNone, clRed, [], blNone, blNone, blNone, blSolid, ftFontAttr);

  //don't use Italic for comments, coz comments often have Unicode
  AddStyle('Comment', clGray, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Comment2', $00C080, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('CommentDoc', $A0B090, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);

  AddStyle('Number', clNavy, clNone, clNone, [fsBold], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Label', $607EB6, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Color', $0080C0, clNone, clNone, [fsBold], blNone, blNone, blNone, blNone, ftFontAttr);

  AddStyle('IncludeBG1', clBlack, clMoneyGreen, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('IncludeBG2', clBlack, clSkyBlue, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('IncludeBG3', clBlack, $F0B0F0, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('IncludeBG4', clBlack, $B0F0F0, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);

  AddStyle('SectionBG1', clBlack, clCream, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('SectionBG2', clBlack, $E0FFE0, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('SectionBG3', clBlack, $F0F0E0, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('SectionBG4', clBlack, $FFE0FF, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);

  AddStyle('BracketBG', clBlack, clMoneyGreen, clGray, [], blSolid, blSolid, blSolid, blSolid, ftFontAttr);
  AddStyle('CurBlockBG', clBlack, $E8E8E8, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);
  AddStyle('SeparLine', clBlack, $00E000, clNone, [], blNone, blNone, blNone, blNone, ftBackGround);

  AddStyle('TagBound', clGray, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('TagId', $F06060, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('TagIdBad', $F06060, clNone, clRed, [], blNone, blNone, blNone, blWavyLine, ftFontAttr);
  AddStyle('TagProp', $40A040, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('TagPropBad', $40A040, clNone, clRed, [], blNone, blNone, blNone, blWavyLine, ftFontAttr);
  AddStyle('TagInclude', clOlive, clNone, clNone, [fsBold], blNone, blNone, blNone, blNone, ftFontAttr);

  AddStyle('LightBG1', clBlack, $8080FF, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('LightBG2', clBlack, clYellow, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('LightBG3', clBlack, $40F040, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('LightBG4', clBlack, $F08080, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('LightBG5', clBlack, $C0C0B0, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);

  AddStyle('Pale1', $A0E0E0, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Pale2', $E0E0A0, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('Pale3', $E0E0E0, clNone, clNone, [], blNone, blNone, blNone, blNone, ftFontAttr);

  AddStyle('TextBold', clBlack, clNone, clNone, [fsBold], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('TextItalic', clBlack, clNone, clNone, [fsItalic], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('TextBoldItalic', clBlack, clNone, clNone, [fsBold, fsItalic], blNone, blNone, blNone, blNone, ftFontAttr);
  AddStyle('TextCross', clBlack, clNone, clNone, [fsStrikeOut], blNone, blNone, blNone, blNone, ftFontAttr);
end;


procedure DoApplyEditorTheme(Ed: TATSynedit);
begin
  Ed.Colors.TextFont:= GetAppColor('EdTextFont');
  Ed.Colors.TextBG:= GetAppColor('EdTextBg');
  Ed.Colors.TextSelFont:= GetAppColor('EdSelFont');
  Ed.Colors.TextSelBG:= GetAppColor('EdSelBg');

  Ed.Colors.TextDisabledFont:= GetAppColor('EdDisableFont');
  Ed.Colors.TextDisabledBG:= GetAppColor('EdDisableBg');
  Ed.Colors.Caret:= GetAppColor('EdCaret');
  Ed.Colors.Markers:= GetAppColor('EdMarkers');
  Ed.Colors.CurrentLineBG:= GetAppColor('EdCurLineBg');
  Ed.Colors.IndentVertLines:= GetAppColor('EdIndentVLine');
  Ed.Colors.UnprintedFont:= GetAppColor('EdUnprintFont');
  Ed.Colors.UnprintedBG:= GetAppColor('EdUnprintBg');
  Ed.Colors.UnprintedHexFont:= GetAppColor('EdUnprintHexFont');
  Ed.Colors.MinimapBorder:= GetAppColor('EdMinimapBorder');
  Ed.Colors.MinimapTooltipBG:= GetAppColor('EdMinimapTooltipBg');
  Ed.Colors.MinimapTooltipBorder:= GetAppColor('EdMinimapTooltipBorder');
  Ed.Colors.StateChanged:= GetAppColor('EdStateChanged');
  Ed.Colors.StateAdded:= GetAppColor('EdStateAdded');
  Ed.Colors.StateSaved:= GetAppColor('EdStateSaved');
  Ed.Colors.BlockStaple:= GetAppColor('EdBlockStaple');
  Ed.Colors.BlockSepLine:= GetAppColor('EdBlockSepLine');
  Ed.Colors.Links:= GetAppColor('EdLinks');
  Ed.Colors.LockedBG:= GetAppColor('EdLockedBg');
  Ed.Colors.ComboboxArrow:= GetAppColor('EdComboArrow');
  Ed.Colors.ComboboxArrowBG:= GetAppColor('EdComboArrowBg');
  Ed.Colors.CollapseLine:= GetAppColor('EdFoldMarkLine');
  Ed.Colors.CollapseMarkFont:= GetAppColor('EdFoldMarkFont');
  Ed.Colors.CollapseMarkBorder:= GetAppColor('EdFoldMarkBorder');
  Ed.Colors.CollapseMarkBG:= GetAppColor('EdFoldMarkBg');

  Ed.Colors.GutterFont:= GetAppColor('EdGutterFont');
  Ed.Colors.GutterBG:= GetAppColor('EdGutterBg');
  Ed.Colors.GutterCaretFont:= GetAppColor('EdGutterCaretFont');
  Ed.Colors.GutterCaretBG:= GetAppColor('EdGutterCaretBg');

  Ed.Colors.BookmarkBG:= GetAppColor('EdBookmarkBg');
  Ed.Colors.RulerFont:= GetAppColor('EdRulerFont');
  Ed.Colors.RulerBG:= GetAppColor('EdRulerBg');

  Ed.Colors.GutterFoldLine:= GetAppColor('EdFoldLine');
  Ed.Colors.GutterFoldLine2:= GetAppColor('EdFoldLine2');
  Ed.Colors.GutterFoldBG:= GetAppColor('EdFoldBg');

  Ed.Colors.MarginRight:= GetAppColor('EdMarginFixed');
  Ed.Colors.MarginCaret:= GetAppColor('EdMarginCaret');
  Ed.Colors.MarginUser:= GetAppColor('EdMarginUser');

  Ed.Colors.MarkedLinesBG:= GetAppColor('EdMarkedRangeBg');
  Ed.Colors.BorderLine:= GetAppColor('EdBorder');
  Ed.Colors.BorderLineFocused:= GetAppColor('EdBorderFocused');

  Ed.Update;
end;

procedure DoStyleAssign(s, s2: TecSyntaxFormat);
begin
  s.FormatType:= s2.FormatType;
  s.Font.Color:= s2.Font.Color;
  s.Font.Style:= s2.Font.Style;
  s.BgColor:= s2.BgColor;
  s.BorderColorLeft:= s2.BorderColorLeft;
  s.BorderColorRight:= s2.BorderColorRight;
  s.BorderColorTop:= s2.BorderColorTop;
  s.BorderColorBottom:= s2.BorderColorBottom;
  s.BorderTypeLeft:= s2.BorderTypeLeft;
  s.BorderTypeRight:= s2.BorderTypeRight;
  s.BorderTypeTop:= s2.BorderTypeTop;
  s.BorderTypeBottom:= s2.BorderTypeBottom;
end;


function GetAppLexerMapFilename(const ALexName: string): string;
begin
  Result:= ExtractFilePath(_GetDllFilename)+'lexers\'+ALexName+'.cuda-lexmap';
end;

function DoApplyLexerStylesMap(an: TecSyntAnalyzer): boolean;
var
  an_sub: TecSubAnalyzerRule;
  value: string;
  st: TecSyntaxFormat;
  fnLexerMap: string;
  i: integer;
begin
  Result:= true;
  if an=nil then exit;
  an.AppliedStylesMap:= true; //prevent recursion later
  if an.Formats.Count=0 then exit;

  //work for sublexers
  for i:= 0 to an.SubAnalyzers.Count-1 do
  begin
    an_sub:= an.SubAnalyzers[i];
    if Assigned(an_sub) and Assigned(an_sub.SyntAnalyzer) and (not an_sub.SyntAnalyzer.AppliedStylesMap) then
      if not DoApplyLexerStylesMap(an_sub.SyntAnalyzer) then
      begin
        //anNotCorrect:= an.SubAnalyzers[i].SyntAnalyzer;
        Result:= false; //not exit
      end;
  end;

  fnLexerMap:= GetAppLexerMapFilename(an.LexerName);
  if not FileExists(fnLexerMap) then exit;

  with TIniFile.Create(fnLexerMap) do
  try
    for i:= 0 to an.Formats.Count-1 do
    begin
      value:= ReadString('map', an.Formats[i].DisplayName, '');
      if value='-' then Continue;
      if value='' then
      begin
        //anNotCorrect:= an;
        Result:= false; //not exit
      end
      else
      begin
        st:= GetAppStyleFromName(value);
        if Assigned(st) then
          DoStyleAssign(an.Formats[i], st);
      end;
    end;
  finally
    Free
  end;
end;


initialization
  DoInitTheme(AppTheme);

end.

