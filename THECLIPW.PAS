{&Delphi+,Use32+}
unit TheClipW;

{ Win32 core functions }

interface

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
     Windows,

     Strings;

procedure coreInit(const AFlags: Longint);
 begin
 end;

procedure coreDone;
 begin
 end;

function coreOpenClipboard: Boolean;
 begin
  coreOpenClipboard:=OpenClipboard(0);
 end;

function coreCloseClipboard: Boolean;
 begin
  coreCloseClipboard:=CloseClipboard;
 end;

function coreEmptyClipboard: Boolean;
 begin
  coreEmptyClipboard:=EmptyClipboard;
 end;

function coreGetClipboardSize: Longint;
 var
  Handle: THandle;
  Locked: Pointer;
 begin
  Handle:=GetClipboardData(CF_OEMTEXT);

  Locked:=GlobalLock(Handle);

  if Assigned(Locked) then
   Result:=StrLen(Locked) + 1
  else
   Result:=0;

  GlobalUnlock(Handle);
 end;

function coreSetClipboardData(Buffer: Pointer; BufferSize: Word): Boolean;
 var
  Handle: THandle;
  Locked: Pointer;
  Size: Longint;
 begin
  Size:=StrLen(Buffer) + 1;

  { CF_TEXT }

  Handle:=GlobalAlloc(gmem_Moveable or gmem_DDEShare, Size);

  Locked:=GlobalLock(Handle);

  OemToChar(Buffer, Locked);

  GlobalUnlock(Handle);

  Result:=SetClipboardData(CF_TEXT, Handle) <> 0;

  { CF_OEMTEXT }

  Handle:=GlobalAlloc(gmem_Moveable or gmem_DDEShare, Size);

  Locked:=GlobalLock(Handle);

  Move(Buffer^, Locked^, Size);

  GlobalUnlock(Handle);

  Result:=Result and (SetClipboardData(CF_OEMTEXT, Handle) <> 0);

  { CF_UNICODE }

  Handle:=GlobalAlloc(gmem_Moveable or gmem_DDEShare, (Size) * 2);

  Locked:=GlobalLock(Handle);

  MultiByteToWideChar(CP_OEMCP, 0, Buffer, -1, Locked, (Size) * 2);

  GlobalUnlock(Handle);

  SetClipboardData(CF_UNICODETEXT, Handle);
 end;

function coreGetClipboardData(Buffer: Pointer): Boolean;
 var
  Handle: THandle;
  Locked: Pointer;
 begin
  Handle:=GetClipboardData(CF_OEMTEXT);

  Locked:=GlobalLock(Handle);

  if Assigned(Locked) then
   begin
    Move(Locked^, Buffer^, StrLen(Locked) + 1);

    Result:=True;
   end
  else
   Result:=False;

  GlobalUnlock(Handle);
 end;

end.
