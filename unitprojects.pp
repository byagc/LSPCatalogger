unit unitprojects;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, DBCtrls,
  DBGrids, SynEdit;

type

  { TFormProjects }

  TFormProjects = class(TForm)
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    DBNavigator1: TDBNavigator;
    Panel1: TPanel;
  private

  public

  end;

var
  FormProjects: TFormProjects;

implementation

{$R *.lfm}

end.

