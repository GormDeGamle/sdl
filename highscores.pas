unit highscores;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

//******************************************************************************
//** types and classes to manage high scores
//******************************************************************************

type
  TScoreEntry = record
    Name: string;
    Score: integer;
  end;

  TScoreList = class
  protected
    FCount: integer;
  public
    Entry: array of TScoreEntry;

    constructor Create(aCount: integer);
    destructor Destroy; override;

    function Add(aName: string; aScore: integer): integer; virtual;             //<- add a hiscore to the list and recieve the index (0 based)
    procedure Assign(aScoreList: TScoreList; DoKeepSize: boolean = TRUE);

    procedure SaveTo(aFile, aSection, aID: string); virtual;
    procedure LoadFrom(aFile, aSection, aID: string); virtual;
    procedure DoSaveTo(aCfg: TIniFile; aSection, aID: string); virtual;
    procedure DoLoadFrom(aCfg: TIniFile; aSection, aID: string); virtual;

    property Count: integer read FCount;
  end;

const
  NoScore: TScoreEntry = (Name: ''; Score: 0);

implementation

//****************************************************************************
// TScoreList
//****************************************************************************

constructor TScoreList.Create(aCount: integer);
begin
  inherited Create;
  FCount := aCount;
  SetLength(Entry, FCount);
end;

destructor TScoreList.Destroy;
begin
  SetLength(Entry, 0);
  inherited;
end;

//------------------------------------------------------------------------------
// add score
//------------------------------------------------------------------------------

function TScoreList.Add(aName: string; aScore: integer): integer;
var
  ii, jj: integer;
begin

  Result := -1;

  for ii := 0 to Count - 1 do begin
    if aScore > Entry[ii].Score then begin
      for jj := Count - 2 downto ii do begin
        Entry[jj + 1] := Entry[jj];
      end;
      Entry[ii].Name  := aName;
      Entry[ii].Score := aScore;

      Result := ii;
      Break;
    end;
  end;
end;

procedure TScoreList.Assign(aScoreList: TScoreList; DoKeepSize: boolean = TRUE);
var
  ii: integer;
begin
  // assign data of another score list
  if not DoKeepSize then begin
    FCount := aScoreList.Count;
    SetLength(Entry, FCount);
  end;
  for ii := 0 to Count - 1 do begin
    if (ii > aScoreList.Count - 1) then
      Entry[ii] := NoScore
    else
      Entry[ii] := aScoreList.Entry[ii]
    ;
  end;
end;

//------------------------------------------------------------------------------
// save / load
//------------------------------------------------------------------------------

procedure TScoreList.SaveTo(aFile, aSection, aID: string);
var
  aCfg: TIniFile;
begin
  aCfg := TIniFile.Create(aFile);
  try
    DoSaveTo(aCfg, aSection, aID);
  finally
    aCfg.Free;
  end;
end;

procedure TScoreList.LoadFrom(aFile, aSection, aID: string);
var
  aCfg: TIniFile;
begin
  aCfg := TIniFile.Create(aFile);
  try
    DoLoadFrom(aCfg, aSection, aID);
  finally
    aCfg.Free;
  end;
end;

procedure TScoreList.DoSaveTo(aCfg: TIniFile; aSection, aID: string);
var
  ii: integer;
begin
  for ii := 0 to Count - 1 do begin
    aCfg.WriteString (aSection, aID + '_Name_'  + IntToStr(ii), Entry[ii].Name);
    aCfg.WriteInteger(aSection, aID + '_Score_' + IntToStr(ii), Entry[ii].Score);
  end;
end;

procedure TScoreList.DoLoadFrom(aCfg: TIniFile; aSection, aID: string);
var
  ii: integer;
begin
  for ii := 0 to Count - 1 do begin
    Entry[ii].Name  := aCfg.ReadString (aSection, aID + '_Name_'  + IntToStr(ii), '');
    Entry[ii].Score := aCfg.ReadInteger(aSection, aID + '_Score_' + IntToStr(ii), 0);
  end;
end;

end.
