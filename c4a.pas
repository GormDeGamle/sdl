unit c4a;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, highscores;

type

  //****************************************************************************
  //** class for dealing with c4a stuff using Fusilli Client V1.2.0.2 by Ziz
  //****************************************************************************
  TC4A = class;

  TC4AState = (c4aIdle, c4aInit, c4aPulling, c4aPushing);

  TC4APullOption = (plTestMe, plFiltered, plThisMonth);                         //<- not all possible options are supported ATM
  TC4APullOptions = set of TC4APullOption;
const
  plMin = plTestMe;
  plMax = plThisMonth;

type
  TC4APushOption = (psNone, psTestMe, psCache);

  TC4AEvent = procedure(aSender: TC4A) of object;

  TC4A = class
  protected
    FGame: string;

    FIsAvailable: boolean;
    FPullOptions: TC4APullOptions;
    FPushOption: TC4APushOption;
    FLongName: string;
    FShortName: string;
    FPassWord: string;
    FEMail: string;
    FPRID: string;
    FState: TC4AState;
    FError: integer;

    FOnPulled: TC4AEvent;
    FOnPushed: TC4AEvent;

    FScores: TScoreList;
    FProcess: TProcess;

    function Init: boolean; virtual;                                            //<- resuts FALSE if state is not idle
    function GetClientOutput: TStringList; virtual;                             //<- creates a new TStringList that must be freed later on
    procedure SetState(aState: TC4AState); virtual;
    function GetHasScores: boolean; virtual;
  public
    constructor Create(aGame: string; aCount: integer);
    destructor Destroy; override;

    function Pull: boolean; virtual;                                            //<- results FALSE if the function ist not possible because the class is not idle
    function Push(aScore: integer): boolean; virtual;                           //<- -"-
    procedure Update; virtual;                                                  //<- update state

    procedure Pulled;
    procedure Pushed;

    property Game: string read FGame;
    property isAvailable: boolean read FIsAvailable;
    property hasScores: boolean read GetHasScores;
    property PullOptions: TC4APullOptions read FPullOptions write FPullOptions;
    property PushOption: TC4APushOption read FPushOption write FPushOption;
    property LongName: string read FLongName;
    property ShortName: string read FShortName;
    property PassWord: string read FPassWord;
    property EMail: string read FEMail;
    property PRID: string read FPRID;

    property State: TC4AState read FState;
    property Scores: TScoreList read FScores;

    property Error: integer read FError;

    // events
    property OnPulled: TC4AEvent read FOnPulled write FOnPulled;
    property OnPushed: TC4AEvent read FOnPushed write FOnPushed;
  end;

const
  {$IFDEF WINDOWS}
  cFc = '.\fusilli.exe';
  {$ELSE}
  cFc = './fusilli';
  {$ENDIF}

  sPullOption: array[plTestMe..plThisMonth] of string = (
    '--test-me',
    '--filtered',
    '--thismonth'
  );

  sPushOption: array[psNone..psCache] of string = (
    '',
    '--test-me',
    '--cache'
  );

  errC4A_OK      =  0;
  errC4A_General = -1;

implementation

//******************************************************************************
//** TC4A
//******************************************************************************

constructor TC4A.Create(aGame: string; aCount: integer);
begin
  inherited Create;

  FScores      := TScoreList.Create(aCount);
  FGame        := aGame;
  FState       := c4aIdle;
  FPullOptions := [plFiltered];
  FPushOption  := psCache;
  FError       := errC4A_OK;

  FOnPulled := nil;
  FOnPushed := nil;

  // worker process for the Fusilli Client
  FProcess := TProcess.Create(nil);
  FProcess.Executable := cFc;
  FProcess.Options    := FProcess.Options + [poNoConsole, poUsePipes, poStdErrToOutput];

  Init;
end;

destructor TC4A.Destroy;
begin
  // Todo: wait for end of process if still running...
  if FProcess.Running then FProcess.Terminate(-1);
  FProcess.Free;
  FScores.Free;
  inherited;
end;

function TC4A.Init: boolean;
var
  aResult: TStringList;
begin
  Result := FALSE;
  if State = c4aIdle then begin
    SetState(c4aInit);
    try
      FProcess.Options := FProcess.Options + [poWaitOnExit];
      try
        // query C4A profile
        FProcess.Parameters.Clear;
        FProcess.Parameters.Add('info');
        FProcess.Parameters.Add('all');

        FProcess.Execute;

        aResult := GetClientOutput;
        try
          FIsAvailable := (aResult.Count >= 5);
          if aResult.Count >= 1 then FLongName  := aResult[0];
          if aResult.Count >= 2 then FShortName := aResult[1];
          if aResult.Count >= 3 then FPassWord  := aResult[2];
          if aResult.Count >= 4 then FEMail     := aResult[3];
          if aResult.Count >= 5 then FPRID      := aResult[4];

        finally
          aResult.Free;
        end;
      finally
        FProcess.Options := FProcess.Options - [poWaitOnExit];
      end;

      Result := TRUE;

    finally
      FState := c4aIdle;
    end;
  end;
end;

function TC4A.GetClientOutput: TStringList;
begin
  Result := TStringList.Create;
  {$IFDEF WINDOWS}
  if FileExists('.\stdout.txt') then Result.LoadFromFile('.\stdout.txt');
  {$ELSE}
  Result.LoadFromStream(FProcess.Output);
  {$ENDIF}
end;

procedure TC4A.SetState(aState: TC4AState);
begin
  FError := errC4A_OK;
  FState := aState;
end;

function TC4A.GetHasScores: boolean;
var
  ii: integer;
begin
  Result := FALSE;
  for ii := 0 to Scores.Count - 1 do begin
    if (Scores.Entry[ii].Name <> NoScore.Name)
    or (Scores.Entry[ii].Score <> NoScore.Score)
    then begin
      Result := TRUE;
      Break;
    end;
  end;
end;

//------------------------------------------------------------------------------
//-- get high scores from server
//------------------------------------------------------------------------------

function TC4A.Pull: boolean;
var
  aOption: TC4APullOption;
begin
  Result := FALSE;
  if State = c4aIdle then begin
    SetState(c4aPulling);

    // query C4A scores
    FProcess.Parameters.Clear;
    for aOption := plMin to plMax do begin
      if aOption in PullOptions then
        FProcess.Parameters.Add(sPullOption[aOption])
      ;
    end;
    FProcess.Parameters.Add('pull');
    FProcess.Parameters.Add(Game);

    FProcess.Execute;

    Result := TRUE;
  end;
end;

//------------------------------------------------------------------------------
//-- send high score to server
//------------------------------------------------------------------------------

function TC4A.Push(aScore: integer): boolean;
begin
  Result := FALSE;
  if State = c4aIdle then begin
    SetState(c4aPushing);

    // send C4A score
    FProcess.Parameters.Clear;
    if PushOption <> psNone then
      FProcess.Parameters.Add(sPushOption[PushOption])
    ;
    FProcess.Parameters.Add('push');
    FProcess.Parameters.Add(Game);
    FProcess.Parameters.Add(IntToStr(aScore));

    FProcess.Execute;

    Result := TRUE;
  end;
end;

//------------------------------------------------------------------------------
//-- more methods
//------------------------------------------------------------------------------

procedure TC4A.Update;
begin
  if not FProcess.Running then begin
    case State of
      c4aPulling:
        Pulled;
      c4aPushing:
        Pushed;
    end;
    FState := c4aIdle;
  end;
end;

procedure TC4A.Pulled;
var
  ii, aScore: integer;
  aResult: TStringList;
begin
  aResult :=  GetClientOutput;
  try
    //error ?
    if aResult.Count > 0 then begin
      if (FError = errC4A_OK) and ((aResult.Count mod 4) <> 0) then
        FError := errC4A_General
      ;
    end;
    for ii := 0 to Scores.Count - 1 do begin
      if  (FError = errC4A_OK)
      and ((ii * 4 + 3) <= aResult.Count)
      then begin
        if not TryStrToInt(aResult[ii * 4 + 2], aScore) then
          aScore := NoScore.Score
        ;
        Scores.Entry[ii].Name  := aResult[ii * 4 + 1];
        Scores.Entry[ii].Score := aScore;
      end
      else begin
        Scores.Entry[ii].Name  := NoScore.Name;
        Scores.Entry[ii].Score := NoScore.Score;
      end;
    end;
  finally
    aResult.Free;
  end;

  if (OnPulled <> nil) then
    OnPulled(Self)
  ;
end;

procedure TC4A.Pushed;
begin
  if (OnPushed <> nil) then
    OnPushed(Self)
  ;
end;

end.
