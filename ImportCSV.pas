﻿unit ImportCSV;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IniFiles, Vcl.Grids, Uni, ImportSetting,
  System.ImageList, Vcl.ImgList, UniProvider, OracleUniProvider, Data.DB, MemDS,
  DBAccess, Vcl.Buttons, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    EditFolderPath: TEdit;
    LabelPath: TLabel;
    StringGridCSV: TStringGrid;
    UniConnection1: TUniConnection;
    UniQuery1: TUniQuery;
    OracleUniProvider1: TOracleUniProvider;
    ImageList1: TImageList;
    SpeedButtonCSVRead: TSpeedButton;
    SpeedButtonCSVImport: TSpeedButton;
    SpeedButtonSetting: TSpeedButton;
    StatusBar1: TStatusBar;
    procedure ButtonFolderSelectClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure StringGridCSVDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure SpeedButtonCSVReadClick(Sender: TObject);
    procedure SpeedButtonCSVImportClick(Sender: TObject);
    procedure SpeedButtonSettingClick(Sender: TObject);
  private
    { Private declarations }
    function GetColumnIndexByHeaderName(StringGrid: TStringGrid; HeaderName: string): Integer;
    function GetCellValueByColumnName(StringGrid: TStringGrid; HeaderName: string; Row: Integer): string;
    function GetStringGridRowData(Grid: TStringGrid; RowIndex: Integer): string;
    procedure CreateStringGrid(var Grid: TStringGrid; AParent: TWinControl);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.ButtonFolderSelectClick(Sender: TObject);
var
  FolderDialog: TFileOpenDialog;
begin
  FolderDialog := TFileOpenDialog.Create(nil);
  try
    FolderDialog.Options := FolderDialog.Options + [fdoPickFolders];
    if FolderDialog.Execute then
    begin
      EditFolderPath.Text := FolderDialog.FileName;
    end;
  finally
    FolderDialog.Free;
  end;
end;

procedure TForm1.SpeedButtonCSVImportClick(Sender: TObject);
var
  i,kmseqno, jdseqno: Integer;
  // Path Value
  CSVFolderPath, LogFolderPath, ErrorLogFolderPath : String;
  // Insert Value
  SEIZONO, BUBAN, KEIKOTEICD, KIKAICD, TANTOCD, JYMDS, JYMDE, JKBN, JMAEDANH, JYUJINH, JMUJINH, JATODANH : String;

  // Cost Value
  YUJINTANKA, KIKAITANKA, KOTEITANKA, YUJINKIN, MUJINKIN, KINSUM : Currency;
  IsInserted, HasErrorLog, HasLog, IsLogDelete, updateYMDS: Boolean;
  ErrorLog: TStringList;
  CurFileName, ErrorFileName: string;
  IniFile: TIniFile;
  FmtSettings: TFormatSettings;
  procedure InitializeFromIniFile;
  begin
    with TIniFile.Create(ExtractFilePath(Application.ExeName) + 'GRD\DS13IACT100.ini') do
    try
      CSVFolderPath := ReadString('Settings', 'FolderPath', '');
      HasLog := ReadBool('Settings', 'HasLogFile', False);
      HasErrorLog := ReadBool('Settings', 'HasErrorFile', False);
      IsLogDelete := (ReadString('Settings', 'Operation', '') = 'Delete');
      LogFolderPath := ReadString('Settings', 'MovePath', '');
      ErrorLogFolderPath := ReadString('Settings', 'ErrorPath', '');
    finally
      Free;
    end;
  end;

  procedure HandleFileOperations;
  begin
    if HasLog then
    begin
      if CurFileName <> '' then
      begin
        if IsLogDelete then
          DeleteFile(CSVFolderPath + '\' + CurFileName)
        else
          RenameFile(CSVFolderPath + '\' + CurFileName, LogFolderPath + '\' + FormatDateTime('yyyymmddHHmm', Now) + '_Log_' + CurFileName);
      end;
    end;
  end;

  procedure LogError;
  begin
    if HasErrorLog then
    begin
      if ErrorLog.Count	> 1 then
       begin
        ErrorLog.SaveToFile(ErrorLogFolderPath + '\' + FormatDateTime('yyyymmddHHmm', Now) + '_Error_' + CurFileName);
        ErrorLog.Clear;
        ErrorLog.Add(GetStringGridRowData(StringGridCSV, 0));
       end;
    end;
  end;

begin
  ErrorLog := TStringList.Create;
  try
    InitializeFromIniFile;
    ErrorLog.Add(GetStringGridRowData(StringGridCSV, 0));
    CurFileName := '';
    // Prepare Date Format Check
    FmtSettings := TFormatSettings.Create;
    FmtSettings.ShortDateFormat := 'dd/mm/yyyy'; // Specify the expected format
    FmtSettings.DateSeparator := '/';
    FormatSettings.LongTimeFormat := 'hh:nn';
    FormatSettings.TimeSeparator := ':';
    // Setup UniQuery using the established connection
    UniQuery1 := TUniQuery.Create(nil);
    try
      UniQuery1.Connection := UniConnection1;

      for i := 1 to StringGridCSV.RowCount - 1 do // Assuming the first row contains headers
      begin
        if GetCellValueByColumnName(StringGridCSV, 'Result', i) = 'NG' then
        begin

          // Case first row
          if CurFileName = '' then
            CurFileName := GetCellValueByColumnName(StringGridCSV, 'Filename', i);

          // Case Change File Name then Create Error Log File And Move File
          if CurFileName <> GetCellValueByColumnName(StringGridCSV, 'Filename', i) then
          begin
            HandleFileOperations;
            LogError;
            CurFileName := GetCellValueByColumnName(StringGridCSV, 'Filename', i);
          end;

          // Add Error Row Data into ErrorLog StringList
          ErrorLog.Add(GetStringGridRowData(StringGridCSV,i));
        end
        else
        begin
        try
          {$REGION '//PREPARE INSRET PARAMETER'}
          //Get all Insert Value
          SEIZONO := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Job No'), i];
          BUBAN := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Sharp'), i];
          KEIKOTEICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Process CD'), i];
          KIKAICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Machine CD'), i];
          TANTOCD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Worker CD'), i];
          JYMDS := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Start Date'), i];
          JYMDE := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'End Date'), i];
          JKBN := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Status'), i];
          JMAEDANH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Pre-Setup'), i];
          JYUJINH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Manned'), i];
          JMUJINH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Unmanned'), i];
          JATODANH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Post-Setup'), i];

          //Get Cost Value
          UniQuery1.SQL.Text := 'SELECT MTANKA, MYUJINTANKA, MMUJINTANKA  FROM KOUTEIKMST WHERE KEIKOTEICD = :KEIKOTEICD';
          UniQuery1.ParamByName('KEIKOTEICD').AsString := KEIKOTEICD;
          UniQuery1.ExecSQL;
          KOTEITANKA := UniQuery1.FieldByName('MTANKA').AsFloat;
          YUJINTANKA := UniQuery1.FieldByName('MYUJINTANKA').AsFloat;
          KIKAITANKA := UniQuery1.FieldByName('MMUJINTANKA').AsFloat;

          YUJINKIN :=  ((StrToInt(JMAEDANH) + StrToInt(JYUJINH) + StrToInt(JATODANH)) * YUJINTANKA) / 60;
          MUJINKIN := (StrToInt(JMUJINH) * KIKAITANKA) / 60;
          KINSUM := YUJINKIN + MUJINKIN;
          //GET KMSEQNO
          UniQuery1.SQL.Text := 'SELECT KMSEQNO FROM keikakumst KM INNER JOIN BUHINKOMST BM ON KM.SEIZONO = BM.SEIZONO AND KM.BUNO = BM.BUNO WHERE BM.SEIZONO = :SEIZONO AND BM.BUBAN = :BUBAN AND KM.KEIKOTEICD = :KEIKOTEICD';
          UniQuery1.ParamByName('SEIZONO').AsString := SEIZONO;
          UniQuery1.ParamByName('BUBAN').AsString := BUBAN;
          UniQuery1.ParamByName('KEIKOTEICD').AsString := KEIKOTEICD;
          UniQuery1.ExecSQL;
          kmseqno := UniQuery1.FieldByName('KMSEQNO').AsInteger;

          //GET NEW JDSEQNO
          UniQuery1.SQL.Text := ' SELECT SEQNO FROM HATUBAN WHERE ID = ''JISEKIDATA''';
          UniQuery1.ExecSQL;
          jdseqno := UniQuery1.FieldByName('SEQNO').AsInteger;
          jdseqno := jdseqno + 1;
          {$ENDREGION}

          {$REGION '//KEIKAKUJWMST'}
            // Check having Leveling data or not
            UniQuery1.SQL.Text :=
              ' SELECT KMSEQNO FROM KEIKAKUJWMST  '#13 +
              ' WHERE KMSEQNO = :KMSEQNO        '#13 +
               '';
            UniQuery1.ParamByName('KMSEQNO').AsInteger := kmseqno;
            UniQuery1.ExecSQL;
            //If not exist then INSERT New
            if UniQuery1.IsEmpty then
              begin
                UniQuery1.SQL.Text :=
                ' INSERT INTO KEIKAKUJWMST                                                                            '#13 +
                '   (KMSEQNO,SETNO,JKBN,JDANKBN,JYMDS,JKEIZOKUYMDS,JMAEYMDE,JKIKAIYMDS,JKIKAIYMDE,JATOYMDS,JYMDE,     '#13 +
                '   JTANTOCD,JKIKAICD,INPTANTOCD,INPYMD,UPDTANTOCD,UPDYMD,SEIZONO)                                    '#13 +
                ' SELECT KMSEQNO,0,:JKBN,:JDANKBN,                                                                    '#13 +
                ' :JYMDS,                                          '#13 +
                ' :JKEIZOKUYMDS,                                   '#13 +
                ' :JMAEYMDE,                                       '#13 +
                ' :JKIKAIYMDS,                                     '#13 +
                ' :JKIKAIYMDE,                                     '#13 +
                ' :JATOYMDS,                                       '#13 +
                ' :JYMDE,                                          '#13 +
                ' LPAD(:JTANTOCD,6),:JKIKAICD,''AUTO'',SYSDATE,''AUTO'',SYSDATE,:SEIZONO        '#13 +
                ' FROM KEIKAKUMST WHERE KMSEQNO = :KMSEQNO                                                            '#13 +
                '';
                updateYMDS := True;
              end
            //If exist then UPDATE
            else
              begin
                // Check JISEKIDATA existing or not? (Case INSERTED discontinue)
                UniQuery1.SQL.Text :=
                  ' SELECT KMSEQNO FROM JISEKIDATA    '#13 +
                  ' WHERE KMSEQNO = :KMSEQNO        '#13 +
                   '';
                UniQuery1.ParamByName('KMSEQNO').AsInteger := kmseqno;
                UniQuery1.ExecSQL;
                // Case NO INSERTED Discontinue Do Update YMDS
                if UniQuery1.IsEmpty then
                  begin
                    UniQuery1.SQL.Text :=
                      ' UPDATE KEIKAKUJWMST SET                                                                             '#13 +
                      '   JYMDS         = :JYMDS,                      '#13 +
                      '   JKEIZOKUYMDS  = :JKEIZOKUYMDS,               '#13 +
                      '   JMAEYMDE      = :JMAEYMDE,                   '#13 +
                      '   JKIKAIYMDS    = :JKIKAIYMDS,                 '#13 +
                      '   JKIKAIYMDE    = :JKIKAIYMDE,                 '#13 +
                      '   JATOYMDS      = :JATOYMDS,                   '#13 +
                      '   JYMDE         = :JYMDE,                      '#13 +
                      '   JKBN          = :JKBN,                                                                            '#13 +
                      '   JDANKBN       = :JDANKBN,                                                                         '#13 +
                      '   JTANTOCD      = LPAD(:JTANTOCD,6),                                                                '#13 +
                      '   JKIKAICD      = :JKIKAICD,                                                                        '#13 +
                      '   SEIZONO       = :SEIZONO,                                                                         '#13 +
                      '   UPDTANTOCD    = ''AUTO'',                                                                         '#13 +
                      '   UPDYMD        = SYSDATE                                                                           '#13 +
                      ' WHERE KMSEQNO   = :KMSEQNO                                                                          '#13 +
                      '';
                    updateYMDS := True;
                  end
                // Case INSERTED Discontinue Not Update YMDS
                else
                  begin
                    UniQuery1.SQL.Text :=
                      ' UPDATE KEIKAKUJWMST SET                                                                             '#13 +
                      '   JMAEYMDE      = :JMAEYMDE,                      '#13 +
                      '   JKIKAIYMDE    = :JKIKAIYMDE,                    '#13 +
                      '   JYMDE         = :JYMDE,                         '#13 +
                      '   JKBN          = :JKBN,                                                                            '#13 +
                      '   JDANKBN       = :JDANKBN,                                                                         '#13 +
                      '   JTANTOCD      = LPAD(:JTANTOCD,6),                                                               '#13 +
                      '   JKIKAICD      = :JKIKAICD,                                                                        '#13 +
                      '   SEIZONO       = :SEIZONO,                                                                         '#13 +
                      '   UPDTANTOCD    = ''AUTปO'',                                                              '#13 +
                      '   UPDYMD        = SYSDATE                                                                           '#13 +
                      ' WHERE KMSEQNO   = :KMSEQNO                                                                          '#13 +
                      '';
                      updateYMDS := False;
                  end;
              end;

            //Check STATUS
            if JKBN = '4' then begin
              UniQuery1.ParamByName('JKBN'        ).AsString    := '4';
              UniQuery1.ParamByName('JDANKBN'     ).AsString    := '0';
            end
            else if JKBN = '5' then begin
              UniQuery1.ParamByName('JKBN'        ).AsString    := '2';
              UniQuery1.ParamByName('JDANKBN'     ).AsString    := '9';
            end
            else if JKBN = '2' then begin
              UniQuery1.ParamByName('JKBN'        ).AsString    := '2';
              UniQuery1.ParamByName('JDANKBN'     ).AsString    := '0';
            end;
            UniQuery1.ParamByName('KMSEQNO'   ).AsInteger       := KMSEQNO;
            UniQuery1.ParamByName('JMAEYMDE'  ).AsDateTime      := StrToDateTime(JYMDE, FmtSettings);
            UniQuery1.ParamByName('JKIKAIYMDE').AsDateTime      := StrToDateTime(JYMDS, FmtSettings);
            UniQuery1.ParamByName('JYMDE'     ).AsDateTime      := StrToDateTime(JYMDE, FmtSettings);
            UniQuery1.ParamByName('JTANTOCD'  ).AsString        := TANTOCD;
            UniQuery1.ParamByName('JKIKAICD'  ).AsString        := KIKAICD;
            UniQuery1.ParamByName('SEIZONO'   ).AsString        := SEIZONO;
            //Check Update YMDS
            if updateYMDS then begin
              UniQuery1.ParamByName('JYMDS'       ).AsDateTime  := StrToDateTime(JYMDS, FmtSettings);
              UniQuery1.ParamByName('JKEIZOKUYMDS').AsDateTime  := StrToDateTime(JYMDE, FmtSettings);
              UniQuery1.ParamByName('JKIKAIYMDS'  ).AsDateTime  := StrToDateTime(JYMDE, FmtSettings);
              UniQuery1.ParamByName('JATOYMDS'    ).AsDateTime  := StrToDateTime(JYMDE, FmtSettings);
            end;
            UniQuery1.ExecSQL;
          {$ENDREGION}

          {$REGION '//JISEKIDATA'}
          UniQuery1.SQL.Text :=
              ' INSERT INTO JISEKIDATA                                                                      '#13 +
              '   (JDSEQNO,KMSEQNO,JDANKBN,SEIZONO,BUSEQNO,KOTEISEQNO,BUNO,KOTEINO,BUBAN,BUNM,              '#13 +
              '   BUCD,KEIKOTEICD,JKOTEICD,GKOTEICD,GHIMOKUCD,SAGYOCD,FURYOCD,JIGUCD,KIKAICD,TANTOCD,       '#13 +
              '   YMDS,YMDE,KEIH,KEIMAEDANH,KEIYUJINH,KEIMUJINH,KEIATODANH,JH,JISEKIBIKOU,                  '#13 +
              '   JMAEDANH,JYUJINH,JMUJINH,JATODANH,JKBN,KAKOSURYO,INPTANTOCD,INPYMD,UPDTANTOCD,UPDYMD,     '#13 +
              '   YUJINTANKA,KIKAITANKA,KOTEITANKA,YUJINKIN,MUJINKIN,KINSUM)                                '#13 +
              ' SELECT :JDSEQNO,:KMSEQNO,0,KM.SEIZONO,BM.BUSEQNO,KM.KOTEISEQNO,BM.BUNO,KM.KOTEINO,BM.BUBAN, '#13 +
              '   BM.BUNM,BM.BUCD,KM.KEIKOTEICD,KM.KEIKOTEICD,1,1,KM.SAGYOCD,KM.FURYOCD,KM.JIGUCD,:KIKAICD,LPAD(:TANTOCD,6) ,:YMDS,:YMDE ,KM.KEIH,  '#13 +
              '   KM.KEIMAEDANH,KM.KEIYUJINH,KM.KEIMUJINH,KM.KEIATODANH,:JH,:JISEKIBIKOU,:JMAEDANH,:JYUJINH,:JMUJINH,    '#13 +
              '   :JATODANH,:JKBN,BM.SURYO,''AUTO'',SYSDATE,''AUTO'',SYSDATE,                          '#13 +
              '   :YUJINTANKA,:KIKAITANKA,:KOTEITANKA,:YUJINKIN,:MUJINKIN,:KINSUM                                                                       '#13 +
              ' FROM KEIKAKUMST KM                                                                          '#13 +
              ' INNER JOIN BUHINKOMST BM ON KM.SEIZONO = BM.SEIZONO AND KM.BUNO = BM.BUNO                   '#13 +
              ' WHERE KMSEQNO = :KMSEQNO                                                                    '#13 + '';
            UniQuery1.ParamByName('JDSEQNO').AsInteger        := jdseqno;
            UniQuery1.ParamByName('KMSEQNO').AsInteger        := KMSEQNO;
            UniQuery1.ParamByName('KIKAICD').AsString         := KIKAICD;
            UniQuery1.ParamByName('TANTOCD').AsString         := TANTOCD;
            UniQuery1.ParamByName('YMDS').AsDateTime          := StrToDateTime(JYMDS, FmtSettings);
            // Case start then complete date = NULL
            if JKBN = '2' then
              UniQuery1.ParamByName('YMDE').AsDateTime        := StrToDateTime(JYMDS, FmtSettings)
            else
              UniQuery1.ParamByName('YMDE').AsDateTime        := StrToDateTime(JYMDE, FmtSettings);

            UniQuery1.ParamByName('JMAEDANH').AsInteger       := StrToInt(JMAEDANH);
            UniQuery1.ParamByName('JYUJINH').AsInteger        := StrToInt(JYUJINH);
            UniQuery1.ParamByName('JMUJINH').AsInteger        := StrToInt(JMUJINH);
            UniQuery1.ParamByName('JATODANH').AsInteger       := StrToInt(JATODANH);
            UniQuery1.ParamByName('JH').AsInteger             := StrToInt(JMAEDANH) + StrToInt(JYUJINH) + StrToInt(JYUJINH) + StrToInt(JATODANH);
            UniQuery1.ParamByName('JKBN').AsInteger           := StrToInt(JKBN);
            UniQuery1.ParamByName('JISEKIBIKOU').AsString     := '';
            UniQuery1.ParamByName('YUJINTANKA').AsFloat       := YUJINTANKA;
            UniQuery1.ParamByName('KIKAITANKA').AsFloat       := KIKAITANKA;
            UniQuery1.ParamByName('KOTEITANKA').AsFloat       := KOTEITANKA;
            UniQuery1.ParamByName('YUJINKIN').AsFloat         := YUJINKIN;
            UniQuery1.ParamByName('MUJINKIN').AsFloat         := MUJINKIN;
            UniQuery1.ParamByName('KINSUM').AsFloat           := KINSUM;

            UniQuery1.ExecSQL;
        {$ENDREGION}

            //Update HATUBAN
            UniQuery1.SQL.Text := 'UPDATE HATUBAN SET SEQNO = :SEQNO WHERE ID = ''JISEKIDATA''';
            UniQuery1.ParamByName('SEQNO').AsInteger  := jdseqno;
            UniQuery1.ExecSQL;

            StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Result'), i] := 'Imported';
        except
          on E: Exception do
          begin
            StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Result'), i] := 'NG Import';
            ErrorLog.Add(GetStringGridRowData(StringGridCSV,i) + ',' +  E.Message);
          end;
        end;

        end;
      end;
      HandleFileOperations;
      LogError;
    finally
      UniQuery1.Free;
    end;
  finally
    ErrorLog.Free;
    SpeedButtonCSVImport.Enabled := False;
    UniConnection1.Free;
  end;
end;

procedure TForm1.SpeedButtonCSVReadClick(Sender: TObject);
var
  FolderPath: string;
  SearchRec: TSearchRec;
  CSVLines: TStringList;
  CurrentRow: Integer;
  FileColumn: Integer;
  FileName: string;

  // Check Has Title
  hasTitle: Boolean;
  StartRow: Integer;

procedure ValidateStringGridCSV;
var
  i, ValidationColIndex: Integer;
  SEIZONO, BUBAN, KEIKOTEICD, KIKAICD, TANTOCD, JYMDS, JYMDE, JKBN, JMAEDANH, JYUJINH, JMUJINH, JATODANH : String;

  IntValue: Integer;
  DateValue: TDateTime;
  FmtSettings: TFormatSettings;
  errorInfo: String;
  isError: Boolean;
begin
  // Prepare Date Format Check
  FmtSettings := TFormatSettings.Create;
  FmtSettings.ShortDateFormat := 'dd/mm/yyyy'; // Specify the expected format
  FmtSettings.DateSeparator := '/';
  FormatSettings.LongTimeFormat := 'hh:nn';
  FormatSettings.TimeSeparator := ':';

  // Add a new column for the validation result if not already added
  ValidationColIndex := GetColumnIndexByHeaderName(StringGridCSV, 'Info');
  if ValidationColIndex = -1 then
  begin
    ValidationColIndex := StringGridCSV.ColCount;
    StringGridCSV.ColCount := StringGridCSV.ColCount + 1;
    StringGridCSV.Cells[ValidationColIndex, 0] := 'Info';
  end;

  for i := 1 to StringGridCSV.RowCount - 1 do
  begin
    // Initial Parameter
    isError := false;
    errorInfo := '';

    // Case 1 SEIZONO existing or not
    SEIZONO := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Job No'), i];
    UniQuery1.SQL.Text := 'SELECT COUNT(*) FROM SEIZOMST WHERE SEIZONO = :SEIZONO';
    UniQuery1.ParamByName('SEIZONO').AsString := SEIZONO;
    UniQuery1.Execute;

    if UniQuery1.IsEmpty then
      begin
        isError := True;
        errorInfo := errorInfo + 'Job No not found, ';
      end;

    // Case 2 KMSEQNO existing or not
    BUBAN := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Sharp'), i];
    KEIKOTEICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Process CD'), i];
    UniQuery1.SQL.Text := 'SELECT KMSEQNO FROM keikakumst KM INNER JOIN BUHINKOMST BM ON KM.SEIZONO = BM.SEIZONO AND KM.BUNO = BM.BUNO WHERE BM.SEIZONO = :SEIZONO AND BM.BUBAN = :BUBAN AND KM.KEIKOTEICD = :KEIKOTEICD';
    UniQuery1.ParamByName('SEIZONO').AsString := SEIZONO;
    UniQuery1.ParamByName('BUBAN').AsString := BUBAN;
    UniQuery1.ParamByName('KEIKOTEICD').AsString := KEIKOTEICD;
    UniQuery1.Execute;

    if UniQuery1.IsEmpty then
      begin
        isError := True;
        errorInfo := errorInfo + 'Barcode not found, ';
      end;

    // Case 3 KIKAICD existing or not
    KIKAICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Machine CD'), i];
    UniQuery1.SQL.Text := 'SELECT KIKAICD FROM KIKAIMST WHERE KIKAICD = :KIKAICD';
    UniQuery1.ParamByName('KIKAICD').AsString := KIKAICD;
    UniQuery1.Execute;

    if UniQuery1.IsEmpty then
      begin
        isError := True;
        errorInfo := errorInfo + 'Machine CD not found, ';
      end;

    // Case 4 TANTOCD existing or not
    TANTOCD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Worker CD'), i];
    UniQuery1.SQL.Text := 'SELECT TANTOCD FROM TANTOMST WHERE TANTOCD = LPAD(:TANTOCD,6)';
    UniQuery1.ParamByName('TANTOCD').AsString := TANTOCD;
    UniQuery1.Execute;

    if UniQuery1.IsEmpty then
      begin
        isError := True;
        errorInfo := errorInfo + 'Worker CD not found, ';
      end;

    // Case 5 Check Date format
    JYMDS := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Start Date'), i];
    JYMDE := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'End Date'), i];
    if Not TryStrToDateTime(JYMDS, DateValue, FmtSettings) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Start Date is invalid format, ';
      end;

    if Not TryStrToDateTime(JYMDE, DateValue, FmtSettings) then
      begin
        isError := True;
        errorInfo := errorInfo + 'End Date is invalid format, ';
      end;

    if (TryStrToDateTime(JYMDS, DateValue, FmtSettings) > TryStrToDateTime(JYMDE, DateValue, FmtSettings)) And Not isError then
      begin
        isError := True;
        errorInfo := errorInfo + 'Start Date is greater than End Date, ';
      end;

    // Case 6 Check status number
    JKBN := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Status'), i];
    if (JKBN <> '4') and (JKBN <> '5') then
      begin
        isError := True;
        errorInfo := errorInfo + 'Status is invalid number, ';
      end;

    // Case 7 check Decimal format
    JMAEDANH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Pre-Setup'), i];
    JYUJINH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Manned'), i];
    JMUJINH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Unmanned'), i];
    JATODANH := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Post-Setup'), i];
    if Not TryStrToInt(JMAEDANH, IntValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Pre-Setup is invalid format, ';
      end;

    if Not TryStrToInt(JYUJINH, IntValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Manned is invalid format, ';
      end;

    if Not TryStrToInt(JMUJINH, IntValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Unmanned is invalid format, ';
      end;

    if Not TryStrToInt(JATODANH, IntValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Post-Setup is invalid format, ';
      end;

    // Check current row error
    if isError then
    begin
       StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Result'), i] := 'NG';
       StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Info'), i] := errorInfo;
    end;
  end;
end;

procedure AdjustGridColumnWidths;
var
  Col, Row: Integer;
  MaxWidth: Integer;
  CurrentWidth: Integer;
  Canvas: TCanvas;
begin
  Canvas := StringGridCSV.Canvas; // Get the canvas of the StringGrid to measure text width

  for Col := 1 to StringGridCSV.ColCount - 1 do
  begin
    MaxWidth := 0;

    for Row := 0 to StringGridCSV.RowCount - 1 do
    begin
      // Measure the width of the text in each cell of the column
      CurrentWidth := Canvas.TextWidth(StringGridCSV.Cells[Col, Row]);

      // Update MaxWidth if the current cell's text is wider
      if CurrentWidth > MaxWidth then
        MaxWidth := CurrentWidth;
    end;

    // Add some padding to the width to avoid clipping the text
    StringGridCSV.ColWidths[Col] := MaxWidth + 30; // Adjust padding as needed
  end;
end;
procedure RemoveTrailingEmptyCells;
var
  LastNonEmptyRow, LastNonEmptyCol, i, j: Integer;
begin
  LastNonEmptyRow := -1;
  LastNonEmptyCol := -1;

  // Find the last non-empty row
  for i := 0 to StringGridCSV.RowCount - 1 do
  begin
    for j := 0 to StringGridCSV.ColCount - 1 do
    begin
      if Trim(StringGridCSV.Cells[j, i]) <> '' then
      begin
        LastNonEmptyRow := i;
        Break;
      end;
    end;
  end;

  // Find the last non-empty column
  for j := 0 to StringGridCSV.ColCount - 1 do
  begin
    for i := 0 to StringGridCSV.RowCount - 1 do
    begin
      if Trim(StringGridCSV.Cells[j, i]) <> '' then
      begin
        LastNonEmptyCol := j;
        Break;
      end;
    end;
  end;

  // Adjust the StringGrid's size
  if LastNonEmptyRow >= 0 then
    StringGridCSV.RowCount := LastNonEmptyRow + 1;
  if LastNonEmptyCol >= 0 then
    StringGridCSV.ColCount := LastNonEmptyCol + 1;
end;
begin
  // Set number of columns
  CreateStringGrid(StringGridCSV, Self);
  hasTitle := True; // Read From Screen Setting
  FolderPath := EditFolderPath.Text; // Assume EditFolderPath is your TEdit

  CurrentRow := 1; // Start after the fixed rows (typically used for headers)
  if FindFirst(FolderPath + '\*.csv', faAnyFile, SearchRec) = 0 then
  begin
    FileColumn := StringGridCSV.ColCount; // Get the index for the new "Filename" column
    StringGridCSV.ColCount := StringGridCSV.ColCount + 1; // Add a new column for filenames
    StringGridCSV.Cells[FileColumn, 0] := 'Filename'; // Set the header for the new column
    repeat
      FileName :=  SearchRec.Name;
      CSVLines := TStringList.Create;
      try
        CSVLines.LoadFromFile(FolderPath + '\' + FileName);
        // Skip the header row for subsequent files
        if hasTitle then
          StartRow := 1
        else
          StartRow := 0;
      // Adjust the grid rows to accommodate the new file
      StringGridCSV.RowCount := StringGridCSV.RowCount + CSVLines.Count - StartRow;
      // Read and populate the StringGrid
      for var Row := StartRow to CSVLines.Count - 1 do
      begin
        var CSVRowData := CSVLines[Row].Split([',']);
        // Ensure the grid has enough columns
        if Length(CSVRowData) + 1 > StringGridCSV.ColCount then
          StringGridCSV.ColCount := Length(CSVRowData);

        // Populate the grid with the FileName in the first column
        StringGridCSV.Cells[FileColumn , CurrentRow] := FileName;

        // Populate the grid
        for var Col := 0 to High(CSVRowData) do
        begin
          StringGridCSV.Cells[Col + 1, CurrentRow] :=  Trim(StringReplace(CSVRowData[Col], '"', '', [rfReplaceAll]));
        end;
        Inc(CurrentRow); // Move to the next row in the StringGrid
      end;
      finally
        CSVLines.Free;
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
  if StringGridCSV.RowCount > 1 then
  begin
    // Remove trailing empty rows and columns
    RemoveTrailingEmptyCells;
    // Check Data Validation
    ValidateStringGridCSV;
    // Adjust width automatic
    AdjustGridColumnWidths;
    // Enable Import Button
    SpeedButtonCSVImport.Enabled := True;
  end;
end;

procedure TForm1.SpeedButtonSettingClick(Sender: TObject);
begin
  Form2 := TForm2.Create(Application);
  Form2.Show;
end;

procedure TForm1.StringGridCSVDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  S: string;
  InfoColumnIndex: Integer;
  Grid: TStringGrid;
const
  CellPadding = 2; // Adjust the padding as needed
begin
  Grid := Sender as TStringGrid;
  S := Grid.Cells[ACol, ARow]; // Get the cell text
  InfoColumnIndex := GetColumnIndexByHeaderName(StringGridCSV, 'Info');
  // Check if this is a header cell
  if ARow = 0 then
  begin
    if (ACol = 0) then
      Grid.Canvas.Brush.Color := clWebLightYellow
    else
      Grid.Canvas.Brush.Color := clWebLightBlue; // Use the specific color you want for the header
    // Header cell formatting

    Grid.Canvas.FillRect(Rect);
    Grid.Canvas.Font.Color := clWindowText;
    DrawText(Grid.Canvas.Handle, PChar(S), Length(S), Rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end
  else if ACol = 0 then // Change for your "Result" column index
  begin
    // "NG" cell formatting
    if AnsiStartsText('NG', S) then
    begin
      Grid.Canvas.Brush.Color := clYellow; // Entire cell background color for "NG" cells
      Grid.Canvas.Font.Color := clRed; // Text color for "NG" cells
      Grid.Canvas.FillRect(Rect); // Fill the cell with the brush color
    end
    else if S = 'Imported' then
    begin
      Grid.Canvas.Brush.Color := clWebLightGreen; // Entire cell background color for "NG" cells
      Grid.Canvas.Font.Color := clBlack; // Text color for "NG" cells
      Grid.Canvas.FillRect(Rect); // Fill the cell with the brush color
    end
    else
    begin
      Grid.Canvas.Brush.Color := clWindow; // Default background color for cells
      Grid.Canvas.Font.Color := clWindowText; // Default text color for cells
      Grid.Canvas.FillRect(Rect); // Fill the cell with the brush color
    end;
    DrawText(Grid.Canvas.Handle, PChar(S), Length(S), Rect, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end
  else if (ARow > 0) and (ACol = InfoColumnIndex) then
  begin
    // Check If Info no blank
    if S <> '' then
    begin
      Grid.Canvas.Brush.Color := clYellow; // Entire cell background color for "NG" cells
      Grid.Canvas.Font.Color := clRed; // Text color for "NG" cells
      Grid.Canvas.FillRect(Rect); // Fill the cell with the brush color
      // Align the text to the left with padding
      Inc(Rect.Left, CellPadding);
      DrawText(Grid.Canvas.Handle, PChar(S), Length(S), Rect, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;
  end
  else
  begin
    // Default cell formatting
    Grid.Canvas.Brush.Color := clWindow; // Default background color for cells
    Grid.Canvas.Font.Color := clWindowText; // Default text color for cells
    Grid.Canvas.FillRect(Rect); // Fill the cell with the brush color
    // Adjust the Rect to add padding on the left
    Inc(Rect.Left);
    DrawText(Grid.Canvas.Handle, PChar(S), Length(S), Rect, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'GRD\DS13IACT100.ini');
  try
    IniFile.WriteString('Settings', 'FolderPath', EditFolderPath.Text);
  finally
    IniFile.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
  ExeFileName, FileVersion: string;

  function GetFileVersion(const FileName: TFileName): string;
  var
    Size, Handle: DWORD;
    Buffer: array of Byte;
    FileInfo: PVSFixedFileInfo;
    FileInfoSize: UINT;
  begin
    Size := GetFileVersionInfoSize(PChar(FileName), Handle);
    if Size = 0 then
      RaiseLastOSError;

    SetLength(Buffer, Size);
    if not GetFileVersionInfo(PChar(FileName), Handle, Size, Buffer) then
      RaiseLastOSError;

    if not VerQueryValue(Buffer, '\', Pointer(FileInfo), FileInfoSize) then
      RaiseLastOSError;

    Result := Format('%d.%d.%d.%d',
      [HiWord(FileInfo.dwFileVersionMS), LoWord(FileInfo.dwFileVersionMS),
       HiWord(FileInfo.dwFileVersionLS), LoWord(FileInfo.dwFileVersionLS)]);
  end;

  procedure LoadConnectionParameters;
  var
    IniFile: TIniFile;
    FileName: string;
    // Can't declare Username, Password *Conflict with UnitConnection Variable Name
    DirectDBName, User, Pass: string;
  begin
    FileName := ExtractFilePath(Application.ExeName) + '/Setup/SetUp.Ini'; // Assumes the INI file is in the same directory as the application
    IniFile := TIniFile.Create(FileName);
    try

      DirectDBName := IniFile.ReadString('Setting', 'DIRECTDBNAME', '');
      User := IniFile.ReadString('Setting', 'USERNAME', '');
      Pass := IniFile.ReadString('Setting', 'PASSWORD', '');
      // Set status bar
      StatusBar1.Panels[2].Text :=  DirectDBName + ' : ' +  User;
      with UniConnection1 do
      begin
        if not Connected then
        begin
          ProviderName := 'Oracle';
          SpecificOptions.Values['Direct'] := 'True';
          Server := DirectDBName;
          Username := User;
          Password := Pass;
          Connect; // Establish the connection
        end;
      end;
    finally
      IniFile.Free; // Always free the TIniFile object when done
    end;
  end;

begin


  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'GRD\DS13IACT100.ini');
  // Get the name of the executable
  ExeFileName := ExtractFileName(Application.ExeName);
  // Get the file version
  FileVersion := GetFileVersion(Application.ExeName);
  // Assuming you have a TStatusBar component named StatusBar1
  // Create the status bar at runtime
  StatusBar1 := TStatusBar.Create(Self);
  StatusBar1.Parent := Self;
  // Add panels to the status bar
  with StatusBar1 do
  begin
    Panels.Add;
    Panels[0].Width := 175; // Set the width as needed
    Panels.Add;
    Panels[1].Width := 140; // Set the width as needed
    Panels.Add;
    Panels[2].Width := 400; // Set the width as needed
    // Set other properties as needed
  end;
  // Set the status bar panels to show the info
  StatusBar1.Panels[0].Text := ' ' + ExeFileName;
  StatusBar1.Panels[1].Text := FileVersion;

  try
    // Init Button Enable
    SpeedButtonCSVRead.Enabled := False;
    SpeedButtonCSVImport.Enabled := False;
    EditFolderPath.Text := IniFile.ReadString('Settings', 'FolderPath', '');
    if Trim(EditFolderPath.Text) <> '' Then
      If DirectoryExists(EditFolderPath.Text) then
        SpeedButtonCSVRead.Enabled := True;


  finally
    IniFile.Free;
  end;
  // Set Connection
  LoadConnectionParameters;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  i: Integer;
  function IsCmdLineSwitch(const Switch: string): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 1 to ParamCount do
    begin
      Result := CompareText(ParamStr(I), '/' + Switch) = 0;
      if Result then Break;
    end;
  end;
begin

  CreateStringGrid(StringGridCSV,Self);
  // Check if there is more than one monitor
  if Screen.MonitorCount > 1 then
  begin
    // Position the form on the second monitor
    Left := Screen.Monitors[1].Left + (Screen.Monitors[1].Width - Width) div 2;
    Top := Screen.Monitors[1].Top + (Screen.Monitors[1].Height - Height) div 2;
  end;
    // After the form is shown, check for command-line parameters
  if IsCmdLineSwitch('AUTO') then
  begin
    // Call the method that handles the Read CSV action
    if SpeedButtonCSVRead.Enabled	= True then
      SpeedButtonCSVReadClick(Self);

    // Call the method that handles the Import action
    if SpeedButtonCSVImport.Enabled = True then
      SpeedButtonCSVImportClick(Self);

    // Close the application
    Application.Terminate;
  end;
end;

function TForm1.GetCellValueByColumnName(StringGrid: TStringGrid; HeaderName: string; Row: Integer): string;
var
  ColIndex: Integer;
begin
  Result := ''; // Default result if header not found or row is out of range
  if (Row < 0) or (Row >= StringGrid.RowCount) then Exit;

  ColIndex := GetColumnIndexByHeaderName(StringGrid, HeaderName);
  if ColIndex >= 0 then
  begin
    Result := StringGrid.Cells[ColIndex, Row];
  end;
end;

function TForm1.GetStringGridRowData(Grid: TStringGrid; RowIndex: Integer): String;
var
  ColIndex: Integer;
  RowData: String;
begin
  RowData := '';
  // Loop through all columns in the row
  for ColIndex := 0 to Grid.ColCount - 1 do
  begin
    // Concatenate the column data with a comma, but skip the last comma
    RowData := RowData + Grid.Cells[ColIndex, RowIndex];
    if ColIndex < Grid.ColCount - 1 then
      RowData := RowData + ',';
  end;
  Result := RowData;
end;


function TForm1.GetColumnIndexByHeaderName(StringGrid: TStringGrid; HeaderName: string): Integer;
var
  Col: Integer;
begin
  Result := -1; // Default result if header not found
  for Col := 0 to StringGrid.ColCount - 1 do
  begin
    if StringGrid.Cells[Col, 0] = HeaderName then // Assuming row 0 has the headers
    begin
      Result := Col;
      Break;
    end;
  end;
end;

procedure TForm1.CreateStringGrid(var Grid: TStringGrid; AParent: TWinControl);
begin


//  for i := 0 to StringGridCSV.ColCount - 1 do
//  begin
//    Grid.ColWidths[i] := Grid.ClientWidth div Grid.ColCount;
//  end;
  // Assign the OnDrawCell event handler
  Grid.OnDrawCell := StringGridCSVDrawCell;

  // Set number of columns
  Grid.ColCount := 15;
  Grid.RowCount := 1;


  // Set the headers
  Grid.Cells[0, 0] := 'Result';
  Grid.Cells[1, 0] := 'Job No';
  Grid.Cells[2, 0] := 'Sharp';
  Grid.Cells[3, 0] := 'Process CD';
  Grid.Cells[4, 0] := 'Machine CD';
  Grid.Cells[5, 0] := 'Machine NM';
  Grid.Cells[6, 0] := 'Worker CD';
  Grid.Cells[7, 0] := 'Worker NM';
  Grid.Cells[8, 0] := 'Start Date';
  Grid.Cells[9, 0] := 'End Date';
  Grid.Cells[10, 0] := 'Status';
  Grid.Cells[11, 0] := 'Pre-Setup';
  Grid.Cells[12, 0] := 'Manned';
  Grid.Cells[13, 0] := 'Unmanned';
  Grid.Cells[14, 0] := 'Post-Setup';
  // Set column widths for result column
  Grid.ColWidths[0] := 120;
  Grid.ColAlignments[0] := taCenter;

  // Set grid options to show lines
  Grid.Options := Grid.Options + [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine];
end;

end.
