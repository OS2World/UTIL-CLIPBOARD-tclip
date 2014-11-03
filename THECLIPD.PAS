unit TheClipD;

{ DOS/DPMI core functions }

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
     NTVDM,

     TheClip;

var
 Flags: Longint;
 Handle: Word;
 UseNTVDMclp: Boolean;
 DisableClipboard: Boolean;

procedure coreInit(const AFlags: Longint);
 var
  RC: Word;
 function NoWINOLDAP: Boolean; assembler;
  asm
   mov  ax, 1700h
   int  2fh
   cmp  ax, 1700h
   je   @no
   xor  ax, ax
   jmp  @quit
   @no:
   mov  ax, 1
  @quit:
  end;
 begin
  Flags:=AFlags;

  UseNTVDMclp:=(Flags and tcDisableNTVDMCLP = 0) and vddSupported;
  DisableClipboard:=Flags and tcDisableClipboard <> 0;

  if UseNTVDMclp then
   begin
    vddLoad('ntvdmclp.dll', 'ntvdmclpRegister', 'ntvdmclpDispatch', RC, Handle);

    UseNTVDMclp:=RC = 0;
   end
  else
   if not DisableClipboard then
    DisableClipboard:=NoWINOLDAP;
 end;

procedure coreDone;
 begin
  if UseNTVDMclp then
   begin
    vddUnload(Handle);

    UseNTVDMclp:=False;
   end;
 end;

procedure coreint; assembler;
 asm
  push ax

  mov al, [DisableClipboard]
  cmp al, 1
  je @@AMF

  mov al, [UseNTVDMclp]
  cmp al, 1
  je @@NTVDMCLP

  pop ax

  int 2fh

  jmp @@quit

 @@AMF:
  pop ax

  xor ax, ax

  jmp @@quit

 @@NTVDMCLP:
  pop cx

  push ds

  mov ax, [Handle]

  cmp cx, 1703h
  jne @@NTVDMCLPgo

  push si
  pop ds
  mov si, cx

 @@NTVDMCLPgo:
  db $c4, $c4, $58, $02

  pop ds

 @@quit:
 end;

function coreOpenClipboard: Boolean; assembler;
 asm
  mov ax, 1701h
  call coreint

  or ax, ax

  jz @@1

  mov ax,1

 @@1:
 end;

function coreCloseClipboard: Boolean; assembler;
 asm
  mov ax, 1708h
  call coreint

  or ax, ax

  jz @@1

  mov ax,1

 @@1:
 end;

function coreEmptyClipboard: Boolean; assembler;
 asm
  mov ax, 1702h
  call coreint

  or ax, ax

  jz @@1

  mov  ax,1

 @@1:
 end;

function coreGetClipboardSize: Longint; assembler;
 asm
  mov  ax, 1704h
  mov  dx, 7h
  call coreint
 end;

function coreSetClipboardData(Buffer: Pointer; BufferSize: Word): Boolean; assembler;
 asm
  les bx, Buffer
  mov cx, BufferSize

  sub si, si

  mov ax, 1703h
  mov dx, 7h

  call coreint

  or ax,ax

  jz @@1

  mov ax,1

 @@1:
 end;

function coreGetClipboardData(Buffer: Pointer): Boolean; assembler;
 asm
  les bx, Buffer

  mov ax, 1705h
  mov dx, 7h

  call coreint

  or ax, ax

  jz @@1

  mov ax, 1

 @@1:
 end;

end.