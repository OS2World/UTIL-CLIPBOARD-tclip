{&Delphi+}
unit TheClipO;

{ OS/2 core functions }

interface

{$IFDEF VIRTUALPASCAL}
uses
     Use32;
{$ENDIF}

procedure coreInit(const AFlags: Longint);
procedure coreDone;

function coreOpenClipboard: Boolean;
function coreCloseClipboard: Boolean;
function coreEmptyClipboard: Boolean;
function coreGetClipboardSize: Longint;
function coreSetClipboardData(Buffer: Pointer; BufferSize: Word): Boolean;
function coreGetClipboardData(Buffer: Pointer): Boolean;

implementation
uses
     Os2DEF,
     Os2BASE,
     Os2PMAPI,

     Strings;

var
 Anchor: HWnd;

procedure coreInit(const AFlags: Longint);
 begin
  Anchor:=WinQueryAnchorBlock(hwnd_Desktop);
 end;

procedure coreDone;
 begin
 end;

function coreOpenClipboard: Boolean;
 begin
  Result:=False;
  
  if Anchor = NULLHANDLE then
   Exit;
   
  Result:=WinOpenClipBrd(Anchor);
 end;

function coreCloseClipboard: Boolean;
 begin
  coreCloseClipboard:=False;
  
  if Anchor = NULLHANDLE then
   Exit;
   
  Result:=WinCloseClipBrd(Anchor);
 end;

function coreEmptyClipboard: Boolean;
 begin
  Result:=WinEmptyClipBrd(Anchor);
 end;

function coreGetClipboardSize: Longint;
 var
  P: PChar;
 begin
  P:=PChar(WinQueryClipBrdData(Anchor, CF_TEXT));
  
  Result:=0;
  
  if P = nil then
   Exit;
  
  if (DosGetSharedMem(P,  pag_Read) <> No_Error) then
   Exit;
  
  Result:=StrLen(P) + 1;
 end;

function coreSetClipboardData(Buffer: Pointer; BufferSize: Word): Boolean;
 var
  P: PChar;
 begin
  DosAllocSharedMem(Pointer(P), nil, BufferSize, pag_Commit or obj_Giveable
    or obj_Gettable or pag_Read or pag_Write);

  if P <> nil then
   begin
    Move(Buffer^, P^, BufferSize);
    
    Result:=WinSetClipBrdData(Anchor, ULong(P), CF_TEXT, CFI_POINTER);
   end
  else
   Result:=False;
 end;

function coreGetClipboardData(Buffer: Pointer): Boolean;
 var
  P: PChar;
 begin
  P:=PChar(WinQueryClipBrdData(Anchor, CF_TEXT));
  
  Result:=False;
  
  if P = nil then
   Exit;
   
  if DosGetSharedMem(P,  pag_Read) <> No_Error then
   Exit;
   
  Move(P^, Buffer^, StrLen(P) + 1);
  
  Result:=True;
 end;

end.