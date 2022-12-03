unit sdlappstates;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdlclasses, sdlfonts, sdlapp, sdltypes;

type
  TStateApp = class;

  //****************************************************************************
  // state machine for handling game states (base classes to inherit from)
  //****************************************************************************

  TBaseState = class
  private
    FOwner: TStateApp;
    FID: integer;
  protected
    //*** events (called by HandleEvent)
    procedure OnActive(aActive: TSDL_ActiveEvent); virtual;
    procedure OnKeyDown(aKey: TSDL_KeyboardEvent); virtual;
    procedure OnKeyUp(aKey: TSDL_KeyboardEvent); virtual;
    procedure OnMouseMotion(aMotion: TSDL_MouseMotionEvent); virtual;
    procedure OnMouseButtonDown(aButton: TSDL_MouseButtonEvent); virtual;
    procedure OnMouseButtonUp(aButton: TSDL_MouseButtonEvent); virtual;
    procedure OnJoyAxisMotion(aJAxis: TSDL_JoyAxisEvent); virtual;
    procedure OnJoyBallMotion(aJBall: TSDL_JoyBallEvent); virtual;
    procedure OnJoyHatMotion(aJHat: TSDL_JoyHatEvent); virtual;
    procedure OnJoyButtonDown(aJButton: TSDL_JoyButtonEvent); virtual;
    procedure OnJoyButtonUp(aJButton: TSDL_JoyButtonEvent); virtual;
    procedure OnVideoResize(aResize: TSDL_ResizeEvent); virtual;
    procedure OnVideoExpose(aExpose: TSDL_ExposeEvent); virtual;
    procedure OnQuit(aQuit: TSDL_QuitEvent); virtual;
    procedure OnUser(aUser: TSDL_UserEvent); virtual;
    procedure OnSysWM(aSysWM: TSDL_SysWMEvent); virtual;

    //*** properties
    function GetFont: TSDLFont; virtual;
  public
    constructor Create(aOwner: TStateApp; aID: integer);

    procedure Update; virtual;
    procedure Render; virtual;

    property Owner: TStateApp read FOwner;                                      //<- app class controlling the state
    property Font: TSDLFont read GetFont;                                       //<- the apps default font
    property ID: integer read FID;                                              //<- unique state-id
  end;

  //****************************************************************************
  // SDL app with support for different states
  //****************************************************************************

  TStateApp = class(TSDLApp)
  protected
    FNextStateID: integer;
    FState: TBaseState;

    procedure OnActive(aActive: TSDL_ActiveEvent); override;
    procedure OnKeyDown(aKey: TSDL_KeyboardEvent); override;
    procedure OnKeyUp(aKey: TSDL_KeyboardEvent); override;
    procedure OnMouseMotion(aMotion: TSDL_MouseMotionEvent); override;
    procedure OnMouseButtonDown(aButton: TSDL_MouseButtonEvent); override;
    procedure OnMouseButtonUp(aButton: TSDL_MouseButtonEvent); override;
    procedure OnJoyAxisMotion(aJAxis: TSDL_JoyAxisEvent); override;
    procedure OnJoyBallMotion(aJBall: TSDL_JoyBallEvent); override;
    procedure OnJoyHatMotion(aJHat: TSDL_JoyHatEvent); override;
    procedure OnJoyButtonDown(aJButton: TSDL_JoyButtonEvent); override;
    procedure OnJoyButtonUp(aJButton: TSDL_JoyButtonEvent); override;
    procedure OnVideoResize(aResize: TSDL_ResizeEvent); override;
    procedure OnVideoExpose(aExpose: TSDL_ExposeEvent); override;
    procedure OnQuit(aQuit: TSDL_QuitEvent); override;
    procedure OnUser(aUser: TSDL_UserEvent); override;
    procedure OnSysWM(aSysWM: TSDL_SysWMEvent); override;

    //*** properties
    function GetCurrentStateID: integer;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure Update; override;                                                 //<- calls ChangeState at the end
    procedure Render; override;                                                 //<- calls the renderer of the current state
    procedure ChangeState; virtual;                                             //<- switches to a different state if necessary
    procedure CreateState(aID: integer); virtual;                               //<- create a state class according to the id (in the descendants)

    property State: TBaseState read FState;
    property CurrentStateID: integer read GetCurrentStateID;
    property NextStateID: integer read FNextStateID write FNextStateID;
  end;

implementation

//******************************************************************************
// TBaseState
//******************************************************************************

constructor TBaseState.Create(aOwner: TStateApp; aID: integer);
begin
  inherited Create;
  FOwner := aOwner;
  FID := aID;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

function TBaseState.GetFont: TSDLFont;
begin
  Result := Owner.Font;
end;

//------------------------------------------------------------------------------

procedure TBaseState.OnActive(aActive: TSDL_ActiveEvent);
begin
end;

procedure TBaseState.OnKeyDown(aKey: TSDL_KeyboardEvent);
begin
end;

procedure TBaseState.OnKeyUp(aKey: TSDL_KeyboardEvent);
begin
end;

procedure TBaseState.OnMouseMotion(aMotion: TSDL_MouseMotionEvent);
begin
end;

procedure TBaseState.OnMouseButtonDown(aButton: TSDL_MouseButtonEvent);
begin
end;

procedure TBaseState.OnMouseButtonUp(aButton: TSDL_MouseButtonEvent);
begin
end;

procedure TBaseState.OnJoyAxisMotion(aJAxis: TSDL_JoyAxisEvent);
begin
end;

procedure TBaseState.OnJoyBallMotion(aJBall: TSDL_JoyBallEvent);
begin
end;

procedure TBaseState.OnJoyHatMotion(aJHat: TSDL_JoyHatEvent);
begin
end;

procedure TBaseState.OnJoyButtonDown(aJButton: TSDL_JoyButtonEvent);
begin
end;

procedure TBaseState.OnJoyButtonUp(aJButton: TSDL_JoyButtonEvent);
begin
end;

procedure TBaseState.OnVideoResize(aResize: TSDL_ResizeEvent);
begin
end;

procedure TBaseState.OnVideoExpose(aExpose: TSDL_ExposeEvent);
begin
end;

procedure TBaseState.OnQuit(aQuit: TSDL_QuitEvent);
begin
end;

procedure TBaseState.OnUser(aUser: TSDL_UserEvent);
begin
end;

procedure TBaseState.OnSysWM(aSysWM: TSDL_SysWMEvent);
begin
end;

//------------------------------------------------------------------------------

procedure TBaseState.Update;
begin
end;

procedure TBaseState.Render;
begin
end;

//******************************************************************************
//*** TStateApp
//******************************************************************************

constructor TStateApp.Create(TheOwner: TComponent);
begin
  inherited;
  FState := nil;
  FNextStateID := ST_NONE;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

function TStateApp.GetCurrentStateID: integer;
begin
  if assigned(State) then
    Result := State.ID
  else
    Result := ST_NONE
  ;
end;

destructor TStateApp.Destroy;
begin
  FState.Free;

  inherited Destroy
end;

//------------------------------------------------------------------------------
// event handling by the current state
//------------------------------------------------------------------------------

procedure TStateApp.OnActive(aActive:  TSDL_ActiveEvent);
begin
  if assigned(State) then
    State.OnActive(aActive);

  inherited;
end;

procedure TStateApp.OnKeyDown(aKey: TSDL_KeyboardEvent);
begin
  if assigned(State) then
    State.OnKeyDown(aKey);

  inherited;
end;

procedure TStateApp.OnKeyUp(aKey: TSDL_KeyboardEvent);
begin
  if assigned(State) then
    State.OnKeyUp(aKey);

  inherited;
end;

procedure TStateApp.OnMouseMotion(aMotion: TSDL_MouseMotionEvent);
begin
  if assigned(State) then
    State.OnMouseMotion(aMotion);

  inherited;
end;

procedure TStateApp.OnMouseButtonDown(aButton: TSDL_MouseButtonEvent);
begin
  if assigned(State) then
    State.OnMouseButtonDown(aButton);

  inherited;
end;

procedure TStateApp.OnMouseButtonUp(aButton: TSDL_MouseButtonEvent);
begin
  if assigned(State) then
    State.OnMouseButtonUp(aButton);

  inherited;
end;

procedure TStateApp.OnJoyAxisMotion(aJAxis: TSDL_JoyAxisEvent);
begin
  if assigned(State) then
    State.OnJoyAxisMotion(aJAxis);

  inherited;
end;

procedure TStateApp.OnJoyBallMotion(aJBall: TSDL_JoyBallEvent);
begin
  if assigned(State) then
    State.OnJoyBallMotion(aJBall);

  inherited;
end;

procedure TStateApp.OnJoyHatMotion(aJHat: TSDL_JoyHatEvent);
begin
  if assigned(State) then
    State.OnJoyHatMotion(aJHat);

  inherited;
end;

procedure TStateApp.OnJoyButtonDown(aJButton: TSDL_JoyButtonEvent);
begin
  if assigned(State) then
    State.OnJoyButtonDown(aJButton);

  inherited;
end;

procedure TStateApp.OnJoyButtonUp(aJButton: TSDL_JoyButtonEvent);
begin
  if assigned(State) then
    State.OnJoyButtonUp(aJButton);

  inherited;
end;

procedure TStateApp.OnVideoResize(aResize: TSDL_ResizeEvent);
begin
  if assigned(State) then
    State.OnVideoResize(aResize);

  inherited;
end;

procedure TStateApp.OnVideoExpose(aExpose: TSDL_ExposeEvent);
begin
  if assigned(State) then
    State.OnVideoExpose(aExpose);

  inherited;
end;

procedure TStateApp.OnQuit(aQuit: TSDL_QuitEvent);
begin
  if assigned(State) then
    State.OnQuit(aQuit);

  inherited;
end;

procedure TStateApp.OnUser(aUser: TSDL_UserEvent);
begin
  if assigned(State) then
    State.OnUser(aUser);

  inherited;
end;

procedure TStateApp.OnSysWM(aSysWM: TSDL_SysWMEvent);
begin
  if assigned(State) then
    State.OnSysWM(aSysWM);

  inherited;
end;

//------------------------------------------------------------------------------
// processing
//------------------------------------------------------------------------------

procedure TStateApp.Update;
begin
  inherited;

  if assigned(State) then
    State.Update;

  ChangeState;
end;

procedure TStateApp.ChangeState;
begin
  if NextStateID <> ST_NONE then begin
    if NextStateID <> ST_EXIT then begin
      FreeAndNil(FState);
    end;

    CreateState(NextStateID);

    NextStateID := ST_NONE;
  end;
end;

procedure TStateApp.CreateState(aID: integer);
begin
end;

//------------------------------------------------------------------------------
// rendering
//------------------------------------------------------------------------------

procedure TStateApp.Render;
begin
  if assigned(State) then
    State.Render;
end;

end.
