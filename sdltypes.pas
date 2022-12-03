unit sdltypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl;

type
  //*** fonts
  TSDLFontRenderType = (frtSolid, frtShaded, frtBlended);

  //*** colors
  TRGBAColor = record
    a: UInt8;
    b: UInt8;
    g: UInt8;
    r: UInt8;
  end;

const
  //*** constants for often used colors (SDL)
  scNone:    TSDL_Color = (r: $00; g: $00; b: $00; Unused: 0);
  scBlack:   TSDL_Color = (r: $01; g: $01; b: $01; Unused: 0);                  //*** nearly black since windows renders $000000 as clear sometimes... why?
  scWhite:   TSDL_Color = (r: $FF; g: $FF; b: $FF; Unused: 0);
  scDkGray:  TSDL_Color = (r: $28; g: $28; b: $28; Unused: 0);
  scGray:    TSDL_Color = (r: $80; g: $80; b: $80; Unused: 0);
  scLtGray:  TSDL_Color = (r: $A0; g: $A0; b: $A0; Unused: 0);
  scRed:     TSDL_Color = (r: $FF; g: $00; b: $00; Unused: 0);
  scGreen:   TSDL_Color = (r: $00; g: $FF; b: $00; Unused: 0);
  scBlue:    TSDL_Color = (r: $00; g: $00; b: $FF; Unused: 0);
  scCyan:    TSDL_Color = (r: $00; g: $FF; b: $FF; Unused: 0);
  scYellow:  TSDL_Color = (r: $FF; g: $FF; b: $00; Unused: 0);
  scMagenta: TSDL_Color = (r: $FF; g: $00; b: $FF; Unused: 0);

  //*** constants for often used colors (SDL_GFX)
  gcNone:    TRGBAColor = (a: $FF; b: $00; g: $00; r: $00);
  gcBlack:   TRGBAColor = (a: $FF; b: $01; g: $01; r: $01);
  gcWhite:   TRGBAColor = (a: $FF; b: $FF; g: $FF; r: $FF);
  gcDkGray:  TRGBAColor = (a: $FF; b: $28; g: $28; r: $28);
  gcGray:    TRGBAColor = (a: $FF; b: $80; g: $80; r: $80);
  gcLtGray:  TRGBAColor = (a: $FF; b: $A0; g: $A0; r: $A0);
  gcRed:     TRGBAColor = (a: $FF; b: $00; g: $00; r: $FF);
  gcGreen:   TRGBAColor = (a: $FF; b: $00; g: $FF; r: $00);
  gcBlue:    TRGBAColor = (a: $FF; b: $FF; g: $00; r: $00);
  gcCyan:    TRGBAColor = (a: $FF; b: $FF; g: $FF; r: $00);
  gcYellow:  TRGBAColor = (a: $FF; b: $00; g: $FF; r: $FF);
  gcMagenta: TRGBAColor = (a: $FF; b: $FF; g: $00; r: $FF);

  gcTransparent: TRGBAColor = (a: $00; b: $00; g: $00; r: $00);

type
  //*** vectors
  TVector2DInt = record
    x: integer;
    y: integer;
  end;

  TVector2DFloat = record
    x: Single;
    y: Single;
  end;

  //*** zoom directions
  TZoomDirection = (zdBoth, zdX, zdY);

  //*** directon of animation (in a tile set)
  TAnimDirection = (
    adNone,               //<- don't move
    adForward,            //<- move to next tile
    adBackward,           //<- move to last tile
    adLeft,               //<- move a column left
    adRight,              //<- move a column right
    adUp,                 //<- move a row up
    adDown,               //<- move a row down
    adRandom,             //<- move randomly back or forth
    adRandomHorizontal,   //<- move randomly a column back or forth
    adRandomVertical)     //<- move randomly a row up or down
  ;

  TAnimType = (
   atOnce,
   atRotating,
   atBackAndForth,
   atRotatingOrStay,      //<- only for random modes
   atBackAndForthOrStay   //<- only for random modes
  );

const
  NullVector2DInt:TVector2DInt = (x: 0; y: 0);
  NullVector2DFloat: TVector2DFloat = (x: 0; y: 0);

  //*** default value fpr FPS
  cDefaultFPS             = 60;
  cDefaultSysInfoInterval = 1000;

  //****************************************************************************
  // state machine
  //****************************************************************************

  //*** state IDs
  ST_EXIT = -1; //<- special state for exiting the game
  ST_NONE = 0;  //<- no (new) state

  //****************************************************************************
  // dummy for no keyboard event
  //****************************************************************************

  keyNone: TSDL_KeySym = (
    scancode: 0;
    sym: 0;
    modifier: 0;
    unicode: 0;
  );

  kbdNone: TSDL_KeyboardEvent = (
    type_: 0;
    which: 0;
    state: 0;
    keysym: (
      scancode: 0;
      sym: 0;
      modifier: 0;
      unicode: 0;
    );
  );

  //****************************************************************************
  // exceptions
  //****************************************************************************

type
  ESDLBaseError = class(Exception);
  ESDLError     = class(ESDLBaseError);
  EIMGError     = class(ESDLBaseError);
  ESDLTileError = class(ESDLBaseError);
  EBoardError   = class(ESDLBaseError);

implementation

end.
