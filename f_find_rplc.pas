unit f_find_rplc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls, CheckLst, EditBtn,
  SynEdit, SynEditTypes, LCLType, ExtCtrls, Buttons;

type

  { TfrmFindRplc }

  TfrmFindRplc = class(TForm)
    btnFindFst: TButton;
    btnFindNxt: TButton;
    btnRplcFst1: TButton;
    btnRplcNxt: TButton;
    btnRplcFst: TButton;
    btnRplcAll: TButton;
    edtFind: TEdit;
    edtRplc: TEdit;
    imglst: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    sbar: TStatusBar;
    sbtnDir: TSpeedButton;
    xbxMatchCase: TCheckBox;
    xbxRplc: TCheckBox;
    xbxWhole: TCheckBox;
    xbxSelectionOnly: TCheckBox;
    procedure btnCancelClick(Sender: TObject);
    procedure btnFindFstClick(Sender: TObject);
    procedure btnRplcFst1Click(Sender: TObject);
    procedure btnRplcFstClick(Sender: TObject);
    procedure edtFindChange(Sender: TObject);
    procedure edtFindKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbtnDirClick(Sender: TObject);
    procedure xbxRplcClick(Sender: TObject);
  private
    is_blk: Boolean;
    mode: String;
    srch_cmp: TSynEdit;
    ts0_result: UInt64;
    start_at, fnd_cnt: UInt64;
    start_pnt: TPoint;
    sql_instance_id: Integer;
    srch_for, rplc_wth: String;
    srch_ops: TSynSearchOptions;
    srch_dir: Integer;
    procedure LoadDefaults;

  public
    procedure SetSrchCmp(const Asrch_cmp: TSynEdit; const Asql_instance_id: Integer);
    procedure DoFindRplc(Sender: TObject);
  end;

var
  frmFindRplc: TfrmFindRplc;


implementation

uses uMain;

{$R *.lfm}

{ TfrmFindRplc }

procedure TfrmFindRplc.FormCreate(Sender: TObject);
begin
  LoadDefaults;
end;

procedure TfrmFindRplc.LoadDefaults;
begin
  srch_dir := 0;
  sbtnDir.Glyph := nil;
  imglst.GetBitmap(srch_dir, sbtnDir.Glyph);
end;

procedure TfrmFindRplc.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
end;

procedure TfrmFindRplc.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmFindRplc.btnFindFstClick(Sender: TObject);
begin
  DoFindRplc(Sender);
end;

procedure TfrmFindRplc.btnRplcFst1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmFindRplc.btnRplcFstClick(Sender: TObject);
begin
  DoFindRplc(Sender);
end;

procedure TfrmFindRplc.edtFindChange(Sender: TObject);
begin
  xbxRplc.Checked := False;
  xbxRplcClick(Sender);
end;

procedure TfrmFindRplc.edtFindKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
    begin
      Key := #0;
      DoFindRplc(btnFindNxt);
    end;
end;

procedure TfrmFindRplc.DoFindRplc(Sender: TObject);
begin
  if (Length(edtFind.Text) = 0) then
    Exit;


  srch_for := edtFind.Text;
  rplc_wth := '';
  srch_ops := [];

  FormMain.ListViewFilterEdit1.Text := srch_for;
  FormMain.Invalidate;
  Application.ProcessMessages;

  start_pnt := srch_cmp.LogicalCaretXY;

  if (srch_dir = 1) then
    Include(srch_ops, ssoBackwards);

  if Sender = btnFindFst then
    Include(srch_ops, ssoEntireScope);

  if Sender = btnFindNxt then
    Include(srch_ops, ssoFindContinue);

  if Sender = btnRplcFst then
    Include(srch_ops, ssoReplace);

  if Sender = btnRplcNxt then
    begin
      Include(srch_ops, ssoReplace);
      Include(srch_ops, ssoFindContinue);
    end;

  if Sender = btnRplcAll then
    Include(srch_ops, ssoReplaceAll);

  if xbxRplc.Checked then
    rplc_wth := edtRplc.Text;

  if xbxSelectionOnly.Checked then
    Include(srch_ops, ssoSelectedOnly);

  if xbxWhole.Checked then
    Include(srch_ops, ssoWholeWord);

  if xbxMatchCase.Checked then
    Include(srch_ops, ssoMatchCase);

  fnd_cnt := srch_cmp.SearchReplaceEx(srch_for, rplc_wth, srch_ops, start_pnt);
  if fnd_cnt > 0 then
    begin
      sbar.Panels[0].Text := ' Start: ' + IntToStr(start_pnt.x) + '.' + IntToStr(start_pnt.y);
      sbar.Panels[1].Text := ' Cursor: ' + IntToStr(srch_cmp.LogicalCaretXY.x) + '.' + IntToStr(srch_cmp.LogicalCaretXY.y);
      sbar.Panels[2].Text := ' Found: ' + IntToStr(fnd_cnt);

      FormMain.sbar.Panels[0].Text := ' Start: ' + IntToStr(start_pnt.x) + '.' + IntToStr(start_pnt.y);
      FormMain.sbar.Panels[1].Text := ' Cursor: ' + IntToStr(srch_cmp.LogicalCaretXY.x) + '.' + IntToStr(srch_cmp.LogicalCaretXY.y);
      FormMain.sbar.Panels[2].Text := ' Found: ' + IntToStr(fnd_cnt);
      if self.Showing then edtFind.SetFocus;
    end
  else
    begin
      ShowMessage('Search term: "' + srch_for + '" not found.');
    end;
end;

procedure TfrmFindRplc.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TfrmFindRplc.sbtnDirClick(Sender: TObject);
begin
  if srch_dir = 0 then
    srch_dir := 1
  else
    srch_dir := 0;

  sbtnDir.Glyph := nil;
  imglst.GetBitmap(srch_dir, sbtnDir.Glyph);

end;

procedure TfrmFindRplc.xbxRplcClick(Sender: TObject);
begin
  edtRplc.Enabled := xbxRplc.Checked;
  btnRplcFst.Enabled := xbxRplc.Checked;
  btnRplcNxt.Enabled := xbxRplc.Checked;
  btnRplcAll.Enabled := xbxRplc.Checked;
end;

procedure TfrmFindRplc.SetSrchCmp(const Asrch_cmp: TSynEdit; const Asql_instance_id: Integer);
begin
  srch_cmp := Asrch_cmp;
  sql_instance_id := Asql_instance_id;
end;

end.

