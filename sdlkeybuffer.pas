unit sdlkeybuffer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdltypes;

type
  //****************************************************************************
  // fifo stack for sdl keys
  //****************************************************************************

  { TKeyBuffer }

  TKeyBufferEvent = procedure(aKey: TSDL_KeyboardEvent) of object;              //<- event that can be fired, when a key is added or removed

  TKeyBuffer = class
  private
    FKey: array of TSDL_KeyboardEvent;
    FFirst: integer;
    FLast: integer;
    FOnPush: TKeyBufferEvent;
    FOnPop: TKeyBufferEvent;
  protected
    function GetKey(aIndex: integer): TSDL_KeyboardEvent; virtual;
    function GetKeyCount: integer; virtual;
    function GetSize: integer; virtual;

    procedure DoPush(aKey: TSDL_KeyboardEvent); virtual;
    function DoPop: TSDL_KeyboardEvent; virtual;

    property First: integer read FFirst;
    property Last: integer read FLast;
  public
    constructor Create(aSize: integer);
    destructor Destroy; override;

    procedure Push(aKey: TSDL_KeyboardEvent);                                   //<- add a key to the buffer
    function Pop: TSDL_KeyboardEvent;                                           //<- get the next key from the buffer

    property Key[aIndex: integer]: TSDL_KeyboardEvent read GetKey;              //<- bufered keys
    property KeyCount: integer read GetKeyCount;                                //<- number of keys n the buffer
    property Size: integer read GetSize;                                        //<- max. number of keys in the buffer

    property OnPush: TKeyBufferEvent read FOnPush write FOnPush;
    property OnPop: TKeyBufferEvent read FOnPop write FOnPop;
  end;

implementation

//******************************************************************************
// TKeyBuffer
//******************************************************************************

constructor TKeyBuffer.Create(aSize: integer);
begin
  inherited Create;

  if aSize < 1 then
    raise EListError.Create('invalid size')
  ;

  FOnPush := nil;
  FOnPop  := nil;

  FFirst := -1;
  FLast  := -1;

  SetLength(FKey, aSize);
end;

destructor TKeyBuffer.Destroy;
begin
  SetLength(FKey, 0);

  inherited Destroy;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

function TKeyBuffer.GetKey(aIndex: integer): TSDL_KeyboardEvent;
begin
  if (aIndex < 0) or (aIndex > KeyCount) then begin
    Result := FKey[aIndex];
  end
  else begin
    raise EListError.Create('Key index out of bounds');
  end;
end;

function TKeyBuffer.GetKeyCount: integer;
begin
  Result := 0;
  if (First >= 0) and (Last >= 0) then begin

    if Last = First then begin
      Result := 1;
    end;

    if Last > First then begin
      Result := (Last - First) + 1;
    end;

    if Last < First then begin
      Result := (Last - First) + Size + 1;
    end;

  end;
end;

function TKeyBuffer.GetSize: integer;
begin
  Result := Length(FKey);
end;

//------------------------------------------------------------------------------
// add and remove keys
//------------------------------------------------------------------------------

procedure TKeyBuffer.Push(aKey: TSDL_KeyboardEvent);
begin
  if KeyCount < Size then begin
    if FOnPush <> nil then FOnPush(aKey);
    DoPush(aKey);
  end;
end;

procedure TKeyBuffer.DoPush(aKey: TSDL_KeyboardEvent);
begin
  if FFirst < 0 then inc(FFirst);
  inc(FLast);
  if FLast > Size - 1 then FLast := 0;

  FKey[FLast] := aKey;
end;

function TKeyBuffer.Pop: TSDL_KeyboardEvent;
begin
  if KeyCount > 0 then begin
    Result := DoPop;
    if FOnPop <> nil then FOnPop(Result);
  end
  else begin
    Result := kbdNone;
  end;
end;

function TKeyBuffer.DoPop: TSDL_KeyboardEvent;
begin
  Result := FKey[FFirst];

  inc(FFirst);
  if FFirst > FLast then begin
    FFirst := -1;
    FLast  := -1;
  end
  else begin
    if FFirst > Size then FFirst := 0;
  end;
end;

end.

