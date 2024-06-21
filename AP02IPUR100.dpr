program AP02IPUR100;

uses
  Vcl.Forms,
  ImportCSV in 'ImportCSV.pas' {Form1},
  ImportSetting in 'ImportSetting.pas' {Form2},
  Vcl.Themes,
  Vcl.Styles,
  DatabaseServiceUnit in 'DatabaseServiceUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Sky');
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
