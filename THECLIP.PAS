{&Use32+}
unit TheClip;

{
 comprehensive clipboard control unit

 supported:     DOS/DPMI INT 2fh/ah=17h services (WINOLDAP: Win9x, Win3.x)
                NTVDMCLP service (WINOLDAP emulation under NT/W2k)
                Win32 native clipboard
                OS/2 native clipboard

 compilers:     Borland Pascal 7.0 (real & protected mode)
                Virtual Pascal 2.0 (Win32 & OS/2 targets)

 v1.03

 (q) by sergey korowkin aka sk // [rAN], 2000.
 (q) by Tatyana Medvedeva aka tm // [ice-lock NPD2000], 2000.
 (q) by Gosha Sakovich, 2:5020/2546.14, 2000. (some fixes)

 2:6033/27@fidonet, http://aux.ru/sk, skank@mail.ru

 sources used:
         Dos Navigator (q) by Ritlabs, http://www.ritlabs.com
         Dos Navigator/w32 (q) by sk, http://www.mart.ru/~fidonet
         Virtual Pascal RTL (q) by fPrint Co UK, http://www.vpascal.com
}

{$IFDEF MSDOS} {$DEFINE DOS} {$ENDIF}
{$IFDEF DPMI}  {$DEFINE DOS} {$ENDIF}

interface
uses
     {$IFDEF WIN32}
     TheClipW,
     {$ENDIF}

     {$IFDEF OS2}
     TheClipO,
     {$ENDIF}

     {$IFDEF DOS}
     TheClipD,
     {$ENDIF}

     Strings,
     Objects;

const
 tcNormal               = $00000000;
 tcDisableNTVDMCLP      = $00000001;
 tcDisableClipboard     = $00000002;

procedure InitClipboard(const AFlags: Longint);
procedure DoneClipboard;

function SetClipboardRaw(Buffer: Pointer; BufferSize: Longint): Boolean;
{ Buffer: указатель на стpоки, pазделенные #13#10 и оканчивающиеся #0 }

function SetClipboardString(const S: String): Boolean;
function SetClipboardStrings(const Strings: PCollection): Boolean;

function GetClipboardSize: Longint;

function GetClipboardRaw(Buffer: Pointer): Boolean;
{ под Buffer должно быть выделено GetClipboardSize байт }

function GetClipboardString(var S: String): Boolean;
function GetClipboardStrings(const Strings: PCollection): Boolean;

{ Turbo Vision Editors compatibility routines }

function SetClipboardCRnz(Buffer: PChar; const BufferSize: Longint): Boolean;
function GetClipboardCRnz(var Buffer: PChar; var BufferSize: Longint): Boolean;
function GetClipboardSizeCRnz: Longint;

{ service stuff }

function CouldAllocate(const Size: Longint): Boolean;

implementation

var
 InternalClipboardInited: Boolean;
 InternalClipboard: Pointer;
 InternalClipboardSize: Word;
 InternalFlags: Longint;

{ Internal Clipboard routines }

function SetInternalClipboard(const Buffer: Pointer; const BufferSize: Longint): Boolean;
 begin
  if not InternalClipboardInited then
   begin
    SetInternalClipboard:=False;

    Exit;
   end;

  if InternalClipboard <> nil then
   FreeMem(InternalClipboard, InternalClipboardSize);

  if (Buffer <> nil) and CouldAllocate(BufferSize) then
   begin
    InternalClipboardSize:=BufferSize;

    GetMem(InternalClipboard, InternalClipboardSize);

    Move(Buffer^, InternalClipboard^, InternalClipboardSize);

    SetInternalClipboard:=True;
   end
  else
   begin
    SetInternalClipboard:=False;

    InternalClipboard:=nil;

    InternalClipboardSize:=0;
   end;
 end;

function GetInternalClipboard(const Buffer: Pointer): Boolean;
 begin
  if not InternalClipboardInited then
   begin
    GetInternalClipboard:=False;

    Exit;
   end;

  if InternalClipboard <> nil then
   begin
    Move(InternalClipboard^, Buffer^, InternalClipboardSize);

    GetInternalClipboard:=True;
   end
  else
   GetInternalClipboard:=False;
 end;

{ InitClipboard }

procedure InitClipboard(const AFlags: Longint);
 begin
  InternalClipboard:=nil;

  InternalClipboardSize:=0;

  InternalClipboardInited:=True;

  InternalFlags:=AFlags;

  coreInit(InternalFlags);
 end;

{ DoneClipboard }

procedure DoneClipboard;
 begin
  SetInternalClipboard(nil, 0);

  InternalClipboardInited:=False;

  coreDone;
 end;

{ SetClipboard... }

function SetClipboardRaw(Buffer: Pointer; BufferSize: Longint): Boolean;
 begin
  if coreOpenClipboard then
   begin
    if coreEmptyClipboard then
     SetClipboardRaw:=coreSetClipboardData(Buffer, BufferSize + 1)
    else
     SetClipboardRaw:=False;

    coreCloseClipboard;
   end
  else
   SetClipboardRaw:=SetInternalClipboard(Buffer, BufferSize);
 end;

function SetClipboardString(const S: String): Boolean;
 var
  P: PChar;
 begin
  if not CouldAllocate(Length(S) + 1) then
   SetClipboardString:=False
  else
   begin
    GetMem(P, Length(S) + 1);

    StrPCopy(P, S);

    SetClipboardString:=SetClipboardRaw(P, Length(S) + 1);

    FreeMem(P, Length(S) + 1);
   end;
 end;

function SetClipboardStrings(const Strings: PCollection): Boolean;
 var
  BufferSize, BufferPos, LineCount: Longint;
  Buffer: PChar;
 procedure CountBufferSize(const S: PString); far;
  begin
   if S = nil then
    Inc(BufferSize, 2)
   else
    Inc(BufferSize, Length(S^) + 2);
  end;
 procedure FillBuffer(const S: PString); far;
  begin
   Inc(LineCount);

   if S = nil then
    begin
     Buffer[BufferPos]:=#13;
     Buffer[BufferPos + 1]:=#10;

     Inc(BufferPos, 2);
    end
   else
    begin
     Move(S^[1], Buffer[BufferPos], Length(S^));

     Inc(BufferPos, Length(S^));

     Buffer[BufferPos]:=#13;
     Buffer[BufferPos + 1]:=#10;

     Inc(BufferPos, 2);
    end;
  end;
 begin
  BufferSize:=0;

  Strings^.ForEach(@CountBufferSize);

  Inc(BufferSize);

  if not CouldAllocate(BufferSize) then
   begin
    SetClipboardStrings:=False;

    Exit;
   end;

  GetMem(Buffer, BufferSize);

  if Buffer = nil then
   SetClipboardStrings:=False
  else
   begin
    BufferPos:=0;

    Strings^.ForEach(@FillBuffer);

    Buffer[BufferPos]:=#0;

    SetClipboardStrings:=SetClipboardRaw(Buffer, BufferSize);

    FreeMem(Buffer, BufferSize);
   end;
 end;

{ GetClipboard... }

function GetClipboardSize: Longint;
 begin
  if coreOpenClipboard then
   begin
    GetClipboardSize:=coreGetClipboardSize;

    coreCloseClipboard;
   end
  else
   GetClipboardSize:=InternalClipboardSize;
 end;

function GetClipboardRaw(Buffer: Pointer): Boolean;
 begin
  if coreOpenClipboard then
   begin
    GetClipboardRaw:=coreGetClipboardData(Buffer);

    coreCloseClipboard;
   end
  else
   GetClipboardRaw:=GetInternalClipboard(Buffer);
 end;

function GetClipboardString(var S: String): Boolean;
 var
  Size, L, K: Longint;
  P: PChar;
 begin
  Size:=GetClipboardSize;

  S:='';

  if (Size = 0) or (not CouldAllocate(Size)) then
   begin
    GetClipboardString:=True;

    Exit;
   end;

  GetMem(P, Size);

  if GetClipboardRaw(P) then
   begin
    L:=Size - 1;

    if L > 255 then
     L:=255;

    for K:=0 to L do
     case P[K] of
      #0, #10, #13: Break;
     else
      S:=Concat(S, P[K]);
     end;

    GetClipboardString:=True;
   end
  else
   GetClipboardString:=False;

  FreeMem(P, Size);
 end;

function GetClipboardStrings(const Strings: PCollection): Boolean;
 var
  Size, K: Longint;
  S: String;
  P: PChar;
 begin
  Strings^.FreeAll;

  Size:=GetClipboardSize;

  if (Size = 0) and (not CouldAllocate(Size)) then
   begin
    GetClipboardStrings:=True;

    Exit;
   end;

  GetMem(P, Size);

  if GetClipboardRaw(P) then
   begin
    S:='';

    for K:=0 to Size - 1 do
     case P[K] of
      #0:
       begin
        if S <> '' then
         Strings^.Insert(NewStr(S));

        S:='';
       end;
      #13:
       begin
        Strings^.Insert(NewStr(S));

        S:='';
       end;
      #10:;
     else
      S:=Concat(S, P[K]);
     end;

    if S <> '' then
     Strings^.Insert(NewStr(S));

    GetClipboardStrings:=True;
   end
  else
   GetClipboardStrings:=False;

  FreeMem(P, Size);
 end;

{ Turbo Vision Editors compatibility routines }

function SetClipboardCRnz(Buffer: PChar; const BufferSize: Longint): Boolean;
 var
  Size, Countdown: Longint;
  Destination: PChar;
  Cur, Dest: ^Char;
 begin
  Size:=0;

  Countdown:=BufferSize;

  Cur:=Pointer(Buffer);

  while Countdown <> 0 do
   begin
    if Cur^ = #13 then
     Inc(Size, 2)
    else
     Inc(Size);

    Inc(Cur);

    Dec(Countdown);
   end;

  Inc(Size);

  if not CouldAllocate(Size) then
   begin
    SetClipboardCRnz:=False;

    Exit;
   end;

  GetMem(Destination, Size);

  Cur:=Pointer(Buffer);
  Dest:=Pointer(Destination);

  Countdown:=BufferSize;

  while Countdown <> 0 do
   begin
    if Cur^ = #13 then
     begin
      Dest^:=#13;

      Inc(Dest);

      Dest^:=#10;
     end
    else
     Dest^:=Cur^;

    Inc(Cur);
    Inc(Dest);

    Dec(Countdown);
   end;

  Dest^:=#0;

  SetClipboardCRnz:=SetClipboardRaw(Destination, Size);

  FreeMem(Destination, Size);
 end;

function GetClipboardCRnz(var Buffer: PChar; var BufferSize: Longint): Boolean;
 var
  Source: Pointer;
  Cur, Dest: ^Char;
  Size: Longint;
 begin
  GetClipboardCRnz:=False;

  Size:=GetClipboardSize;

  if (Size = 0) or (not CouldAllocate(Size)) then
   Exit;

  BufferSize:=0;

  GetMem(Source, Size);

  if not GetClipboardRaw(Source) then
   begin
    FreeMem(Source, Size);

    Exit;
   end;

  Cur:=Source;

  while Cur^ <> #0 do
   begin
    if Cur^ <> #10 then
     Inc(BufferSize);

    Inc(Cur);
   end;

  GetMem(Buffer, BufferSize);

  Cur:=Source;
  Dest:=Pointer(Buffer);

  while Cur^ <> #0 do
   begin
    if Cur^ <> #10 then
     begin
      Dest^:=Cur^;

      Inc(Dest);
     end;

    Inc(Cur);
   end;

  FreeMem(Source, Size);

  GetClipboardCRnz:=True;
 end;

function GetClipboardSizeCRnz: Longint;
 var
  Size: Longint;
 begin
  Size:=GetClipboardSize;

  if Size > 0 then
   Dec(Size);

  GetClipboardSizeCRnz:=Size;
 end;

{ CouldAllocate }

function CouldAllocate(const Size: Longint): Boolean;
 begin
  {$IFDEF DOS}
  CouldAllocate:=(Size <= $FFF0) and (MaxAvail >= Size);
  {$ELSE}
  CouldAllocate:=True;
  {$ENDIF}
 end;

end.