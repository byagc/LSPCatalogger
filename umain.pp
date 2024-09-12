unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, JSONPropStorage, f_find_rplc, unitprojects, DB
  , SynEdit, SynHighlighterMulti, SynFacilHighlighter, SynEditMarkupHighAll
  , ListViewFilterEdit, ListFilterEdit, StrUtils, EditBtn, LCLType, DBCtrls, Buttons, ZConnection, ZDataset
  ;

type

  TLspItem = class
    ID: integer;
    Title: string;
    Text: string;
    LineCount: Integer;
    blocked: boolean;

  end;

  { TFormMain }

  TFormMain = class(TForm)
    Button1: TButton;
    DBMemo1: TDBMemo;
    dsProjects: TDataSource;
    lblRegraDescricao: TEdit;
    JSONPropStorage1: TJSONPropStorage;
    Label1: TLabel;
    lblRegraID: TLabel;
    ListView1: TListView;
    ListViewFilterEdit1: TListViewFilterEdit;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    PanelLeft: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    sbar: TStatusBar;
    SpeedButton1: TSpeedButton;
    Splitter1: TSplitter;
    Editor: TSynEdit;
    tsSessions: TTabSheet;
    ZConnection1: TZConnection;
    tblProjects: TZTable;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);

    procedure Button1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);

    procedure ListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure ListViewFilterEdit1AfterFilter(Sender: TObject);
    procedure ListViewFilterEdit1KeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure tblProjectsAfterScroll(DataSet: TDataSet);
  private
    bProcessing: boolean;
    hlt: TSynFacilSyn;
    SearchForm: TfrmFindRplc;
    FormProjects: TFormProjects;

    procedure AddList;
  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure Split(Delimiter: char; Str: string; ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := True;
  ListOfStrings.DelimitedText := Str;
end;

procedure TFormMain.AddList();
var
  aParts: TStringDynArray;
  sText, sPartString, sID, sTitle: string;
  iCount, iPos, iEndPos: SizeInt;
  I: integer;
  LspItem: TLspItem;
  ListItem: TListViewDataItem;

  OutPutList: TStringList;

  function _doAdd(iLast: boolean; iIndex: integer): boolean;
  begin
    LspItem := TLspItem.Create;
    sPartString := aParts[iIndex];
    iPos := pos(' - Descrição: ', sPartString);
    iEndPos := pos(#13#10'-------', sPartString);
    sID := Trim(copy(sPartString, 0, iPos));
    sTitle := Trim(copy(sPartString, iPos + 16, iEndPos - iPos - 16));
    iPos := pos('----------'#13#10, sPartString);
    Delete(sPartString, 1, iPos + 13);
    if not iLast then Delete(sPartString, sPartString.Length - 83, 82);
    if sPartString.Length < 3 then exit;

    OutPutList.Text := sPartString;

    LspItem.ID := sID.ToInteger;
    LspItem.Title := sTitle;
    LspItem.Text := sPartString;
    LspItem.LineCount := OutPutList.Count;
    LspItem.blocked := sPartString.Contains('A regra não pode ser exibida pois está protegida');
    ListItem.Data := LspItem;
    SetLength(ListItem.StringArray, 5);
    ListItem.StringArray[0] := sID;
    if (LspItem.blocked) then
      ListItem.StringArray[1] := 'B'
    else
      ListItem.StringArray[1] := '';
    ListItem.StringArray[2] := LspItem.LineCount.ToString;
    ListItem.StringArray[3] := LspItem.Title;
    ListItem.StringArray[4] := LspItem.Text;
    ListViewFilterEdit1.Items.Add(ListItem);
  end;

begin
  bProcessing := True;
  ListView1.BeginUpdate;
  hlt.LoadFromFile('lspsenior.xml');
  try
    OutPutList := TStringList.Create;
    ListViewFilterEdit1.Items.Clear;
    sText := tblProjects.FieldByName('content').AsString;
    aParts := SplitString(sText, 'Código: ');
    iCount := Length(aParts);
    lblRegraDescricao.Text := iCount.ToString;
    for I := 1 to Pred(iCount) do
    begin
      _doAdd(I = Pred(iCount), I);
    end;
    ListViewFilterEdit1.InvalidateFilter;
    ListViewFilterEdit1.ResetFilter;
    ListViewFilterEdit1.Text := '';
  finally
    bProcessing := False;
    ListView1.EndUpdate;
    OutPutList.Free;
  end;
end;

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  hlt.Free;
end;

procedure TFormMain.Button1Click(Sender: TObject);
begin
  hlt.LoadFromFile('lspsenior.xml');
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  sPath, sHLTFileName: string;
begin
  Editor.Lines.Clear;

  lblRegraDescricao.Text := '';
  sPath := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
  ZConnection1.LibraryLocation := sPath + 'sqlite3_x86.dll';
  ZConnection1.Database := sPath + 'data.sqlite';
  JSONPropStorage1.JSONFileName := ChangeFileExt(Application.ExeName, '.cfg');

  sHLTFileName := 'lspsenior.xml';
  hlt := TSynFacilSyn.Create(self);
  Editor.Highlighter := hlt;
  if (FileExists(sPath + sHLTFileName)) then
    hlt.LoadFromFile(sPath + sHLTFileName);

  SearchForm := TfrmFindRplc.Create(Self);
  SearchForm.SetSrchCmp(Editor, 0);
  FormProjects := TFormProjects.Create(Self);
  tblProjects.Open;

end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_F3 then
  begin
    SearchForm.DoFindRplc(SearchForm.btnFindNxt);
  end;
  if (Key = VK_F) and (ssCtrl in Shift) then
  begin
    SearchForm.Show;
  end;
  if (Key = VK_N) and (ssCtrl in Shift) then
  begin
    FormProjects.ShowModal;
  end;
end;

procedure TFormMain.ListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if (not bProcessing) then
  begin
    if (Item.Data <> nil) then
    begin
      Editor.Text := TLspItem(Item.Data).Text;
      lblRegraID.Caption := TLspItem(Item.Data).ID.ToString;
      lblRegraDescricao.Text := TLspItem(Item.Data).Title;
    end;
  end;
end;

procedure TFormMain.ListViewFilterEdit1AfterFilter(Sender: TObject);
begin
  SearchForm.edtFind.Text := ListViewFilterEdit1.Text;
end;

procedure TFormMain.ListViewFilterEdit1KeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    SearchForm.DoFindRplc(SearchForm.btnFindNxt);
  end;
end;

procedure TFormMain.SpeedButton1Click(Sender: TObject);
begin
  FormProjects.ShowModal;
end;

procedure TFormMain.tblProjectsAfterScroll(DataSet: TDataSet);
begin
  AddList;
end;

end.
