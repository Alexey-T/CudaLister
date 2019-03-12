library CudaLister;

{$mode objfpc}{$H+}

uses
  Windows, SysUtils, Forms, Interfaces,
  Controls,
  FileUtil,
  StrUtils,
  IniFiles,
  file_proc,
  form_main,
  form_options, proc_themes, form_listbox;

const
  cDetectString: string = '';
  BusyClose: boolean = false;

const
  LISTPLUGIN_OK    = 0;
  LISTPLUGIN_ERROR = 1;
  lc_copy          = 1;
  lc_newparams     = 2;
  lc_selectall     = 3;
  lc_setpercent    = 4;

  lcp_wraptext     = 1;
  lcp_fittowindow  = 2;
  lcp_ansi         = 4;
  lcp_ascii        = 8;
  lcp_variable     = 12;
  lcp_forceshow    = 16;

  lcs_findfirst    = 1;
  lcs_matchcase    = 2;
  lcs_wholewords   = 4;
  lcs_backwards    = 8;

  itm_percent      = $FFFE;
  itm_fontstyle    = $FFFD;
  itm_wrap         = $FFFC;
  itm_fit          = $FFFB;


procedure LoadGlobalOptions;
begin
  with TIniFile.Create(ListerIniFilename) do
  try
    OptNoCaret:= ReadBool(ListerIniSection, 'no_caret', false);
    OptOnlyKnownTypes:= ReadBool(ListerIniSection, 'only_known_types', false);
    OptMaxFileSizeMb:= ReadInteger(ListerIniSection, 'max_size', OptMaxFileSizeMb);
    OptThemeUi:= ReadString(ListerIniSection, 'theme_ui', '-');
    OptThemeSyntax:= ReadString(ListerIniSection, 'theme_syntax', '-');
  finally
    Free
  end;
end;

procedure ListGetDetectString(DetectString: PChar; MaxLen: integer); stdcall;
begin
  StrLCopy(DetectString, PChar(cDetectString), MaxLen);
end;

function ListLoadW(ListerWin: HWND; FileNamePtr: PWideChar; ShowFlags: integer): HWND; stdcall;
var
  fn: string;
begin
  Result:= 0;
  LoadGlobalOptions;
  fn:= UTF8Encode(WideString(FileNamePtr));
  if not FileExists(fn) then exit;
  if IsFileTooBig(fn) then exit;
  if not IsFileText(fn) then exit;
  if not IsCheckedLexerForFilename(fn) then exit;

  Result := TfmMain.PluginShow(ListerWin, fn, (ShowFlags and lcp_wraptext)<>0);
end;

function ListLoad(ListerWin: HWND; FileNamePtr: PChar; ShowFlags: integer): HWND; stdcall;
begin
  Result:= ListLoadW(ListerWin, PWideChar(WideString(string(FileNamePtr))), ShowFlags);
end;

procedure ListCloseWindow(PluginWin: HWND); stdcall;
begin
  if BusyClose then exit;
  BusyClose:= true;

  TfmMain.PluginHide(PluginWin);

  BusyClose:= false;
end;

type
  TListDefaultParamStruct = record
    size,
    PluginInterfaceVersionLow,
    PluginInterfaceVersionHi: DWORD;
    DefaultIniName: array[0..MAX_PATH-1] of AnsiChar;
  end;
  pListDefaultParamStruct = ^TListDefaultParamStruct;

procedure ListSetDefaultParams(dps: pListDefaultParamStruct); stdcall;
begin
  ListerIniFilename:= string(dps^.DefaultIniName);
end;

function ListLoadNextW(ParentWin, ListWin: HWND;
  FileToLoad: PWideChar;
  ShowFlags: integer): integer; stdcall;
var
  fn: string;
  Form: TfmMain;
begin
  Result:= LISTPLUGIN_ERROR;
  fn:= UTF8Encode(WideString(FileToLoad));
  if (fn='') or (fn[Length(fn)]='\') then exit;
  if IsFileTooBig(fn) then exit;
  if not IsFileText(fn) then exit;

  Form:= TfmMain(FindControl(ListWin));
  if Assigned(Form) then
  begin
    Form.ConfirmSave;
    Form.FileOpen(fn);
    Result:= LISTPLUGIN_OK;
  end;
end;

function ListLoadNext(ParentWin, ListWin: HWND;
  FileToLoad: PChar;
  ShowFlags: integer): integer; stdcall;
begin
  Result:= ListLoadNextW(ParentWin, ListWin,
    PWideChar(WideString(string(FileToLoad))), ShowFlags);
end;

function ListSendCommand(ListWin: HWND;
  Command, Parameter: integer): integer; stdcall;
var
  Form: TfmMain;
begin
  Result:= LISTPLUGIN_OK;
  Form:= TfmMain(FindControl(ListWin));
  if Form=nil then exit;

  case Command of
    lc_copy:
      Form.mnuTextCopyClick(nil);
    lc_selectall:
      Form.mnuTextSelClick(nil);
    lc_setpercent:
      begin
        Form.ed.LineTop:= Form.ed.Strings.Count*Parameter div 100;
        PostMessage(ListWin, WM_COMMAND, MAKELONG(Parameter, itm_percent), Form.Handle);
      end;
    lc_newparams:
      begin
        Form.SetWrapMode((Parameter and lcp_wraptext)=lcp_wraptext);

        ////don't change encoding for A/S keys, otherwise W(wrap) key will change enc too
        //if (Parameter and lcp_ansi)=lcp_ansi then
        //  Form.SetEncodingName(cEncNameAnsi);
        //if (Parameter and lcp_ascii)=lcp_ascii then
        //  Form.SetEncodingName(cEncNameOem);
      end;
  end;
end;


function ListSearchTextW(ListWin: HWND;
  SearchString: PWideChar;
  SearchParameter: integer): integer; stdcall;
var
  Form: TfmMain;
begin
  Result:= LISTPLUGIN_OK;
  Form:= TfmMain(FindControl(ListWin));
  if Assigned(Form) then
    Form.DoFind(
      (SearchParameter and lcs_findfirst)=0,
      (SearchParameter and lcs_backwards)<>0,
      (SearchParameter and lcs_matchcase)<>0,
      (SearchParameter and lcs_wholewords)<>0,
      WideString(SearchString)
      );
end;

function ListSearchText(ListWin: HWND;
  SearchString: PChar;
  SearchParameter: integer): integer; stdcall;
begin
  Result:= ListSearchTextW(ListWin,
    PWideChar(WideString(string(SearchString))),
    SearchParameter);
end;


exports
  ListSetDefaultParams,
  ListGetDetectString,
  ListLoad,
  ListLoadW,
  ListLoadNext,
  ListLoadNextW,
  ListCloseWindow,
  ListSendCommand,
  ListSearchText,
  ListSearchTextW;

begin
  Application.ShowHint:= false;
  Application.ShowButtonGlyphs:= sbgNever;
  Application.Initialize;
end.
   
