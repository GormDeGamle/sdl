unit sdltools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdltypes, sdl_image, sdl_gfx, Math;

//*** TODO: Alt
type
  { TCircle }
  TCircle = record
    x, y: integer;
    r: integer;
  end;

function CheckCollision(a, b: SDL_Rect): boolean;
function CheckCollision(a, b: array of SDL_Rect): boolean;
function CheckCollision(a, b: array of TCircle): boolean;
function CheckCollision(a: array of TCircle; b: array of SDL_Rect): boolean;
function Distance(x1, y1: integer; x2, y2: integer): double;
//*** TODO: Ende Alt

type
  //*** record for storing internal system infos
  TSysInfo = record
    FPS: integer;                                                               //<- measured FPS
    DoShow: boolean;                                                            //<- show sysinfo on screen?
    DoUpdate: boolean;                                                          //<- measure sysinfo values?
    UpdateInterval: integer;                                                    //<- how often? (in ticks = ms)
    LastUpdate: integer;                                                        //<- last update
  end;

procedure ApplySurface(x, y: integer; Source, Dest: PSDL_Surface; Clip: PSDL_Rect = nil);

//*** color funtions
function SDLtoRGBA(aSDLColor: TSDL_Color): TColorRGBA;
function RGBAtoSDL(aRGBAColor: TColorRGBA): TSDL_Color;
function RGBAtoUInt32(aRGBAColor: TColorRGBA): UInt32;
function MakeRGBA(aR, aG, aB, aA: byte): TRGBAColor;
function MakeRGB(aR, aG, aB: byte): TSDL_Color;
//*** image loading functions
function LoadImage(aFileName: string): PSDL_Surface;
function LoadImage(aFileName: string; ckr, ckg, ckb: integer): PSDL_Surface;
function LoadImage(aFileName: string; aColorKey: TSDL_Color): PSDL_Surface;
//*** surface manipulation
procedure ReplaceColor(aSurface: PSDL_Surface; aOldColor, aNewColor: TSDL_Color);
procedure ReplaceAlpha(aSurface: PSDL_Surface; aColor: TSDL_Color; aAlpha: UInt8);

procedure HandleSDLError(aStatus: integer);
procedure HandleIMGError(aStatus: integer);

implementation

procedure HandleSDLError(aStatus: integer);
begin
  //*** check the Result of a SDL call and raise an exception if necessary
  if (aStatus < 0) then begin
    raise ESDLError.Create(SDL_GetError);
  end;
end;

procedure HandleIMGError(aStatus: integer);
begin
  //*** check the Result of an IMG call and raise an exception if necessary
  if (aStatus < 0) then begin
    raise EIMGError.Create(IMG_GetError);
  end;
end;

procedure ApplySurface(x, y: integer; Source, Dest: PSDL_Surface; Clip: PSDL_Rect = nil);
var
  Offset: TSDL_Rect;
begin
  //*** Offset festlegen...
  Offset.x := x;
  Offset.y := y;
  //*** Zeichnen...
  SDL_BlitSurface(Source, Clip, Dest, @Offset);
end;

//------------------------------------------------------------------------------
// color functions
//------------------------------------------------------------------------------

function RGBAtoSDL(aRGBAColor: TColorRGBA): TSDL_Color;
begin
  Result := TSDL_Color(aRGBAColor);
  Result.unused := 0;
end;

function SDLtoRGBA(aSDLColor: TSDL_Color): TColorRGBA;
begin
  Result := TColorRGBA(aSDLColor);
  Result.a := 255; //<- alpha value
end;

function RGBAtoUInt32(aRGBAColor: TColorRGBA): UInt32;
var
  aReverseColor: TRGBAColor;
begin
  aReverseColor.r := aRGBAColor.r;;
  aReverseColor.g := aRGBAColor.g;;
  aReverseColor.b := aRGBAColor.b;;
  aReverseColor.a := aRGBAColor.a;;

  Result := UInt32(aReverseColor);
end;

function MakeRGBA(aR, aG, aB, aA: byte): TRGBAColor;
begin
  Result.r := aR;
  Result.g := aG;
  Result.b := aB;
  Result.a := aA;
end;

function MakeRGB(aR, aG, aB: byte): TSDL_Color;
begin
  Result.r := aR;
  Result.g := aG;
  Result.b := aB;
  Result.unused := 0;
end;

//------------------------------------------------------------------------------
// image loading functions
//------------------------------------------------------------------------------

function LoadImage(aFileName: string): PSDL_Surface;
var
  LoadedImage: PSDL_Surface;
begin
  //*** load an image and convert it to the format of the video buffer...
  Result := nil;
  LoadedImage := IMG_Load(PChar(aFileName));
  if assigned(LoadedImage) then begin
    Result := SDL_DisplayFormatAlpha(LoadedImage); //<- use an alpha channel
    SDL_FreeSurface(LoadedImage);
  end;
end;

function LoadImage(aFileName: string; ckr, ckg, ckb: integer): PSDL_Surface;
var
  LoadedImage: PSDL_Surface;
  ColorKey: UInt32;
begin
  //*** load an image, convert it to the format of the video buffer and set the color key...
  Result := nil;
  LoadedImage := IMG_Load(PChar(aFileName));
  if assigned(LoadedImage) then
  begin
    Result := SDL_DisplayFormat(LoadedImage); //<- don't use an alpha channel (but a color key instead)
    if assigned(Result) then
    begin
      //*** colorkey depending on the resulting surface...
      ColorKey := SDL_MapRGB(Result^.Format, ckr, ckg, ckb);
      //*** ...und verwenden
      SDL_SetColorKey(Result, SDL_SRCCOLORKEY, ColorKey);
    end;
    SDL_FreeSurface(LoadedImage);
  end;
end;

function LoadImage(aFileName: string; aColorKey: TSDL_Color): PSDL_Surface;
begin
  Result := LoadImage(aFileName, aColorKey.r, aColorKey.g, aColorKey.b);
end;

//*** surface manipulation

procedure ReplaceColor(aSurface: PSDL_Surface; aOldColor, aNewColor: TSDL_Color);
var
  xx, yy: integer;
  r, g, b, a: UInt8;
  pixel: ^UInt32;
begin
  SDL_LockSurface(aSurface);
  try
    for yy := 0 to aSurface^.h - 1 do begin
      for xx := 0 to aSurface^.w - 1 do begin
        Pixel := aSurface^.pixels + yy * aSurface^.pitch + xx * aSurface^.format^.BytesPerPixel;
        SDL_GetRGBA(Pixel^, aSurface^.format, @r, @g,  @b, @a);
        if ((r = aOldColor.r) and (g = aOldColor.g) and (b = aOldColor.b)) then begin
          Pixel^ := SDL_MapRGBA(aSurface^.format, aNewColor.r, aNewColor.g, aNewColor.b, a);
        end;
      end;
    end;
  finally
    SDL_UnlockSurface(aSurface);
  end;
end;

procedure ReplaceAlpha(aSurface: PSDL_Surface; aColor: TSDL_Color; aAlpha: UInt8);
var
  xx, yy: integer;
  r, g, b, a: UInt8;
  pixel: ^UInt32;
begin
  SDL_LockSurface(aSurface);
  try
    for yy := 0 to aSurface^.h - 1 do begin
      for xx := 0 to aSurface^.w - 1 do begin
        Pixel := aSurface^.pixels + yy * aSurface^.pitch + xx * aSurface^.format^.BytesPerPixel;
        SDL_GetRGBA(Pixel^, aSurface^.format, @r, @g,  @b, @a);
        if ((r = aColor.r) and (g = aColor.g) and (b = aColor.b)) then begin
          Pixel^ := SDL_MapRGBA(aSurface^.format, r, g, b, aAlpha);
        end;
      end;
    end;
  finally
    SDL_UnlockSurface(aSurface);
  end;
end;

//*** TODO: Alt
function CheckCollision(a, b: SDL_Rect): boolean;
var
  LeftA, LeftB: integer;
  RightA, RightB: integer;
  TopA, TopB: integer;
  BottomA, BottomB: integer;
begin
  Result := True;

  LeftA   := a.x;
  RightA  := a.x + a.w;
  TopA    := a.y;
  BottomA := a.y + a.h;

  LeftB   := b.x;
  RightB  := b.x + b.w;
  TopB    := b.y;
  BottomB := b.y + b.h;

  if (BottomA < TopB) then
    Result := False
  else if (TopA > BottomB) then
    Result := False
  else if (RightA < LeftB) then
    Result := False
  else if (LeftA > RightB) then
    Result := False
  ;
end;

function CheckCollision(a, b: array of SDL_Rect): boolean;
var
  LeftA, LeftB: integer;
  RightA, RightB: integer;
  TopA, TopB: integer;
  BottomA, BottomB: integer;
  aBox, bBox: SDL_Rect;
begin
  //*** Über die A-Rechtecke iterieren...
  Result := False;

  for aBox in a do begin
    LeftA   := aBox.x;
    RightA  := aBox.x + aBox.w;
    TopA    := aBox.y;
    BottomA := aBox.y + aBox.h;

    //*** Über die B-Rechtecke iterieren...
    for bBox in b do begin
      LeftB   := bBox.x;
      RightB  := bBox.x + bBox.w;
      TopB    := bBox.y;
      BottomB := bBox.y + bBox.h;

      if not ((BottomA < TopB) or (TopA > BottomB) or (RightA < LeftB) or (LeftA > RightB)) then
        Result := True
      ;

      if Result then Break;
    end;

    if Result then Break;
  end;
end;

function CheckCollision(a, b: array of TCircle): boolean;
var
  aCircle, bCircle: TCircle;
begin
  Result := False;

  //*** Über die A-Kreise iterieren...
  for aCircle in a do begin
    //*** Über die B-Kreise iterieren...
    for bCircle in b do begin
      if Distance(aCircle.x, aCircle.y, bCircle.x, bCircle.y) < (aCircle.r + bCircle.r) then
        Result := True
      ;

      if Result then Break;
    end;

    if Result then Break;
  end;
end;

function CheckCollision(a: array of TCircle; b: array of SDL_Rect): boolean;
var
  cX, cY: integer; //*** Nächster Punkt der Collission-Box
  aCircle: TCircle;
  bBox: SDL_Rect;
begin
  Result := False;

  //*** Über die A-Kreise iterieren...
  for aCircle in a do begin
    //*** Über die B-Kreise iterieren...
    for bBox in b do begin
      if aCircle.x < bBox.x then
        cX := bBox.x //*** Linker Rand
      else if aCircle.x > bBox.x + bBox.w then
        cX := bBox.x + bBox.w //*** Rechter Rand
      else
        cX := aCircle.x //*** Kreismittelpunkt
      ;

      if aCircle.y < bBox.y then
        cY := bBox.y //*** Oberer Rand
      else if aCircle.y > bBox.y + bBox.h then
        cY := bBox.y + bBox.h //*** Unterer Rand
      else
        cY := aCircle.y //*** Kreismittelpunkt
      ;

      Result := Distance(aCircle.x, aCircle.y, cX, cY) < aCircle.r;

      if Result then Break;
    end;

    if Result then Break;
  end;
end;

function Distance(x1, y1: integer; x2, y2: integer): double;
begin
  Result := Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2));
end;
//*** TODO: Alt

end.

