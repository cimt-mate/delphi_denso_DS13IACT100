﻿unit ImportCSV;

interface

uses
  Winsock,Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, System.StrUtils,
  System.NetEncoding,Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IniFiles, Vcl.Grids, ImportSetting,
  System.ImageList, Vcl.ImgList,  MemDS,REST.Client,System.JSON, System.Net.HttpClient,System.Net.URLClient,
  Vcl.Buttons, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    EditFolderPath: TEdit;
    LabelPath: TLabel;
    StringGridCSV: TStringGrid;
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
    function GetDoctorURL: string;
    function GetSQLJson(const SQLCmd: string): string;
    function GetDataFromREST(const SQLJson: string): string;
    function GetSessionID(const DoctorURL: string): string;
    function Base64Encode(const InputStr: string): string;
    function GeneratePurchaseJSONData(i: Integer): TJSONObject;
    function PostDataToREST(const SQLJson: string): string;
    function GetEXELogIdFromREST: string;
    procedure ClearStringGrid(Grid: TStringGrid);
  public
    { Public declarations }
    SessionID: String;
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
  IsInserted, HasErrorLog, HasLog, IsLogDelete, updateYMDS: Boolean;
  ErrorLog: TStringList;
  CurFileName, ErrorFileName: string;
  IniFile: TIniFile;
  PurchaseJSONData: TJSONObject;
  procedure InitializeFromIniFile;
  begin
    with TIniFile.Create(ExtractFilePath(Application.ExeName) + 'GRD\' + ChangeFileExt(ExtractFileName(Application.ExeName),'') + '.ini') do
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
    // Setup UniQuery using the established connection
    try
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

            PurchaseJSONData := GeneratePurchaseJSONData(i);
            ShowMessage(PostDataToREST(PurchaseJSONData.ToString));
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

    end;
  finally
    ErrorLog.Free;
    SpeedButtonCSVImport.Enabled := False;

  end;
end;

procedure TForm1.ClearStringGrid(Grid: TStringGrid);
var
  Row, Col: Integer;
begin
  for Row := 0 to Grid.RowCount - 1 do
    for Col := 0 to Grid.ColCount - 1 do
      Grid.Cells[Col, Row] := '';

  Grid.RowCount := 1;
  Grid.ColCount := 1;
  Grid.Cells[0, 0] := 'Result'; // Reset the header if needed
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
  FloatValue: Double;
  DateValue: TDateTime;
  FmtSettings: TFormatSettings;
  errorInfo: String;
  isError: Boolean;
  SQLCmd: String;
  SQLJson: String;
  JSONData: String;
  SEIZONO: String;
  BUBAN: String;
  KEIKOTEICD: String;
  YMDS: String;
  YMDE:String;
  SICD: String;
  SURYO: String;
  TANKA: String;
  KINGAKU: String;
begin

  // Get session ID
  SessionID := GetSessionID(GetDoctorURL());

  // Prepare Date Format Check
  FmtSettings := TFormatSettings.Create;
  FmtSettings.ShortDateFormat := 'yyyy/mm/dd'; // Specify the expected format
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
    SEIZONO := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Mfg No'), i];
    // (1) Prepare SQL
    // Escape single quotes by replacing each single quote with two single quotes
    SEIZONO := StringReplace(SEIZONO, '''', '''''', [rfReplaceAll]);

    // Use Format to construct the SQL command
    SQLCmd := Format('SELECT SEIZONO FROM SEIZOMST WHERE SEIZONO = ''%s''', [SEIZONO]);

    // (2) Get SQL JSON
    SQLJson := GetSQLJson(SQLCmd);
    // (3) Get Data From REST
    if GetDataFromREST(SQLJson) = '' then
      begin
        isError := True;
        errorInfo := errorInfo + 'Job No not found, ';
      end;

    // Case 2 Can get barcode or not or not
    BUBAN := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Part No'), i];
    KEIKOTEICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Process CD'), i];
    // (1) Prepare SQL
    SQLCmd := 'SELECT KMSEQNO FROM KEIKAKUMST KM INNER JOIN BUHINKOMST BM ON KM.SEIZONO = BM.SEIZONO AND KM.BUNO = BM.BUNO WHERE KM.SEIZONO = ''' + SEIZONO + ''' AND BM.BUBAN = ''' + BUBAN + ''' AND KM.KEIKOTEICD = ''' + KEIKOTEICD + '''';
    // (2) Get SQL JSON
    SQLJson := GetSQLJson(SQLCmd);
    // (3) Get Data From REST
    if GetDataFromREST(SQLJson) = '' then
      begin
        isError := True;
        errorInfo := errorInfo + 'Barcode not found, ';
      end;

    // Case 3 Check Date format
    YMDS := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'PO Date'), i];
    YMDE := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Receive Date'), i];
    if Not TryStrToDateTime(YMDS, DateValue, FmtSettings) then
      begin
        isError := True;
        errorInfo := errorInfo + 'PO Date is invalid format, ';
      end;

    if Not TryStrToDateTime(YMDE, DateValue, FmtSettings) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Received Date is invalid format, ';
      end;

    if (TryStrToDateTime(YMDS, DateValue, FmtSettings) > TryStrToDateTime(YMDE, DateValue, FmtSettings)) And Not isError then
      begin
        isError := True;
        errorInfo := errorInfo + 'PO Date is greater than Received Date, ';
      end;

    // Case 4 Supplier CD existing or not
    SICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Supplier CD'), i];
    // (1) Prepare SQL
        SQLCmd := 'SELECT SICD FROM SIIREMST WHERE SICD = ''' + SICD + '''';
    SQLJson := GetSQLJson(SQLCmd);
    // (3) Get Data From REST
    if GetDataFromREST(SQLJson) = '' then
      begin
        isError := True;
        errorInfo := errorInfo + 'Supplier Code not found, ';
      end;

    // Case 5 check Decimal format
    SURYO := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Qty'), i];
    TANKA := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Unit Price'), i];
    KINGAKU := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Total'), i];
    if Not TryStrToFloat(SURYO, FloatValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Qty is not Decimal ';
      end;

    if Not TryStrToFloat(TANKA, FloatValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Unit Price is not Decimal ';
      end;

    if Not TryStrToFloat(KINGAKU, FloatValue) then
      begin
        isError := True;
        errorInfo := errorInfo + 'Total Price is not Decimal ';
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

  // Clear the StringGrid before reading new data
  ClearStringGrid(StringGridCSV);

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
  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'GRD\' + ChangeFileExt(ExtractFileName(Application.ExeName),'') + '.ini');
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
    IniFile: TMemIniFile;
    FileName: string;
    // Can't declare Username, Password *Conflict with UnitConnection Variable Name
    DoctorURL: string;
  begin
    FileName := ExtractFilePath(Application.ExeName) + '/Setup/SetUp.Ini'; // Assumes the INI file is in the same directory as the application
    IniFile := TMemIniFile.Create(FileName, TEncoding.UTF8); // Correct class and encoding
    try

      DoctorURL := IniFile.ReadString('Setting', 'DOCTOR_URL', '');
      // Set status bar
      StatusBar1.Panels[2].Text :=  DoctorURL;
    finally
      IniFile.Free; // Always free the TIniFile object when done
    end;
  end;

begin


  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'GRD\' + ChangeFileExt(ExtractFileName(Application.ExeName),'') + '.ini');
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
    Panels[0].Width := 200; // Set the width as needed
    Panels.Add;
    Panels[1].Width := 200; // Set the width as needed
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
  // Assign the OnDrawCell event handler
  Grid.OnDrawCell := StringGridCSVDrawCell;

  // Set number of columns
  Grid.ColCount := 11;
  Grid.RowCount := 1;


  // Set the headers
  Grid.Cells[0, 0] := 'Result';
  Grid.Cells[1, 0] := 'Mfg No';
  Grid.Cells[2, 0] := 'Part No';
  Grid.Cells[3, 0] := 'Process CD';
  Grid.Cells[4, 0] := 'PO Date';
  Grid.Cells[5, 0] := 'Receive Date';
  Grid.Cells[6, 0] := 'Supplier CD';
  Grid.Cells[7, 0] := 'Supplier NM';
  Grid.Cells[8, 0] := 'Qty';
  Grid.Cells[9, 0] := 'Unit Price';
  Grid.Cells[10, 0] := 'Total';
  // Set column widths for result column
  Grid.ColWidths[0] := 120;
  Grid.ColAlignments[0] := taCenter;

  // Set grid options to show lines
  Grid.Options := Grid.Options + [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine];
  // Set grid stick with screen size
  Grid.Anchors := [akLeft, akTop, akRight, akBottom];
end;

function TForm1.GetDoctorURL: string;
var
  IniFile: TMemIniFile;
  FileName: string;
  // Can't declare Username, Password *Conflict with UnitConnection Variable Name
  DoctorURL: string;
begin
  FileName := ExtractFilePath(Application.ExeName) + '/Setup/SetUp.Ini'; // Assumes the INI file is in the same directory as the application
  IniFile := TMemIniFile.Create(FileName, TEncoding.UTF8); // Correct class and encoding
  try

    DoctorURL := IniFile.ReadString('Setting', 'DOCTOR_URL', '');
    // Set status bar
    Result :=  DoctorURL;
  finally
    IniFile.Free; // Always free the TIniFile object when done
  end;
end;

function TForm1.GetSQLJson(const SQLCmd: string): string;
var
  PayloadArray: TJSONArray;
  SQLData, TantoCD: TJSONObject;
begin
  PayloadArray := TJSONArray.Create;
  try
    // Create the SQLDATA JSON object and add it to the payload array
    SQLData := TJSONObject.Create;
    SQLData.AddPair('key', 'SQLDATA');
    SQLData.AddPair('value1', Base64Encode(SQLCmd));
    SQLData.AddPair('value2', TJSONNull.Create);
    PayloadArray.Add(SQLData);

    // Create the TANTOCD JSON object and add it to the payload array
    TantoCD := TJSONObject.Create;
    TantoCD.AddPair('key', 'TANTOCD');
    TantoCD.AddPair('value1', 'admin');
    TantoCD.AddPair('value2', '');
    PayloadArray.Add(TantoCD);

    // Convert the payload array to JSON string
    Result := PayloadArray.ToJSON;
  finally
    PayloadArray.Free;
  end;
end;

function TForm1.Base64Encode(const InputStr: string): string;
begin
  Result := TNetEncoding.Base64.Encode(InputStr);
end;

function TForm1.GetSessionID(const DoctorURL: string): string;
var
  HTTPClient: THTTPClient;
  Response: IHTTPResponse;
  JSONValue: TJSONValue;
  DataJSON: TJSONObject;
begin
  HTTPClient := THTTPClient.Create;
  try
    DataJSON := TJSONObject.Create;
    try
      DataJSON.AddPair('loginID', 'admin');
      DataJSON.AddPair('passWord', 'admin');

      Response := HTTPClient.Post(DoctorURL + '/api/login', TStringStream.Create(DataJSON.ToString), nil);

      if Response.StatusCode = 200 then
      begin
        JSONValue := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8));
        try
          if JSONValue.TryGetValue('sessionID', Result) then
            Exit(Result);
        finally
          JSONValue.Free;
        end;
      end
      else
        raise Exception.Create('Error: ' + Response.StatusCode.ToString + ' - ' + Response.StatusText);

    finally
      DataJSON.Free;
    end;
  finally
    HTTPClient.Free;
  end;
  Result := '';
end;


function TForm1.GetDataFromREST(const SQLJson: string): string;
var
  Client: THttpClient;
  Response: IHttpResponse;
  JSONValue: TJSONValue;
  DataArray: TJSONArray;
  Item: TJSONObject;
begin
  Client := THttpClient.Create;
  try
    Client.ContentType := 'application/json';
    Client.CustomHeaders['SESSIONID'] := SessionID;
    Client.CustomHeaders['Accept'] := 'application/json';
    Client.CustomHeaders['Authorization'] :=  'Bearer ' + SessionID;
    // Send the POST request
    Response := Client.Post(GetDoctorURL() + '/api/sql/sqltool/open', TStringStream.Create(SQLJson, TEncoding.UTF8), nil);
    try
      if Response.StatusCode = 200 then
      begin
        JSONValue := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8));
        if JSONValue <> nil then
        try
          // Check if the root element is an object and retrieve the 'data' array
          if JSONValue is TJSONObject then
          begin
            DataArray := TJSONObject(JSONValue).GetValue('data') as TJSONArray;
            if (DataArray <> nil) and (DataArray.Count > 0) then
            begin
              // Convert the data array to string to return it
              Result := DataArray.ToString;
            end
            else
            begin
              Result := '';
            end;
          end;
        finally
          JSONValue.Free;
        end
        else
        begin
          Result := '';
        end;
      end
      else
      begin
        Result := '';
      end;
    finally
//        Response.ContentStream.Free;
    end;
  finally
    Client.Free;
  end;
end;

function TForm1.GetEXELogIdFromREST: string;
var
  Client: THttpClient;
  Response: IHttpResponse;
  JSONValue: TJSONValue;
  Item: TJSONObject;
  PCName: String;
  EXELogPostJSON: String;
  SystemInfo,SettingData: TJSONObject;
function GetPCName: string;
var
  Buffer: array[0..MAX_COMPUTERNAME_LENGTH] of Char; // Buffer for the computer name
  Size: DWORD; // Size of the computer name
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1; // Set the size of the buffer
  if GetComputerName(Buffer, Size) then
    Result := Buffer // If successful, set the result to the computer name
  else
    Result := 'Unknown'; // If there's an error, return 'Unknown'
end;

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

function GetIPFromName(Name:string):String;
var
  WSAData: TWSAData;
  HostEnt: PHostEnt;
  begin
    result:='';
    WSAStartup(2, WSAData);
    HostEnt := GetHostByName(PAnsiChar(Name));
    if HostEnt <> nil then
    begin
    with HostEnt^ do
    result:= Format('%d.%d.%d.%d',[Byte(h_addr^[0]), Byte(h_addr^[1]),Byte(h_addr^[2]), Byte(h_addr^[3])]);
    end;
    WSACleanup;
end;

begin
  SystemInfo := TJSONObject.Create;
  PCName := GetEnvironmentVariable('COMPUTERNAME');

  Client := THttpClient.Create;
  try
    // Prepare System Info to get EXE Log ID
    SystemInfo.AddPair('terminal', GetEnvironmentVariable('COMPUTERNAME'));
    SystemInfo.AddPair('exename', ExtractFileName(Application.ExeName));
    SystemInfo.AddPair('tantocd', 'admin'); // Example placeholder
    SystemInfo.AddPair('ip1', '192');
    SystemInfo.AddPair('ip2', '168');
    SystemInfo.AddPair('ip3', '10');
    SystemInfo.AddPair('ip4', '111');
    SystemInfo.AddPair('macaddress', '2C-3B-70-58-31-BD');
    SystemInfo.AddPair('username', GetEnvironmentVariable('USERNAME'));
    SystemInfo.AddPair('version', GetFileVersion(ExtractFileName(Application.ExeName))); // Example placeholder for version
    SystemInfo.AddPair('family_id', 0);
    SystemInfo.AddPair('lctype', 0);
    SystemInfo.AddPair('lcvalue', '');

    EXELogPostJSON := SystemInfo.ToJSON;

    // Post to API to get EXE Log ID
    Client.ContentType := 'application/json';
    Client.CustomHeaders['SESSIONID'] := SessionID;
    Client.CustomHeaders['Accept'] := 'application/json';
    Client.CustomHeaders['Authorization'] :=  'Bearer ' + SessionID;
    // Send the POST request
    Response := Client.Post(GetDoctorURL() + '/api/setting/initialize', TStringStream.Create(EXELogPostJSON, TEncoding.UTF8), nil);
    try
      if Response.StatusCode = 200 then
      begin
        JSONValue := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8));
        if JSONValue <> nil then
        try
          // Check if the root element is an object and retrieve the 'data' array
          if JSONValue is TJSONObject then
          begin
            SettingData := TJSONObject(JSONValue).GetValue('setting_data') as TJSONObject;
            if Assigned(SettingData) then
              begin
                Result := SettingData.GetValue('logid').Value;
              end
            else
            begin
              Result := '';
            end;
          end;
        finally
          JSONValue.Free;
        end
        else
        begin
          Result := '';
        end;
      end
      else
      begin
        Result := '';
      end;
    finally
//        Response.ContentStream.Free;
    end;
  finally
    Client.Free;
  end;
end;

function TForm1.PostDataToREST(const SQLJson: string): string;
var
  Client: THttpClient;
  Response: IHttpResponse;
  JSONValue: TJSONValue;
  DataArray: TJSONArray;
  PostURL, EXELogId: String;
begin
  Result := '';
  Client := THttpClient.Create;
  PostURL := GetDoctorURL() + '/api/actual/cost/outsourcing';
  try
    EXELogId := GetEXELogIdFromREST();
    Client.ContentType := 'application/json';
    Client.CustomHeaders['SESSIONID'] := SessionID;
    Client.CustomHeaders['Accept'] := 'application/json';
    Client.CustomHeaders['Authorization'] :=  'Bearer ' + SessionID;
    Client.CustomHeaders['exelogid'] := EXELogId;
    // Send the POST request
    Response := Client.Post(PostURL, TStringStream.Create(SQLJson, TEncoding.UTF8), nil);
    try
      if Response.StatusCode = 200 then
      begin
        Result := 'Imported OK';
      end
      else
      begin
        Result := 'Imported NG';
      end;
    finally
//        Response.ContentStream.Free;
    end;
  finally
    Client.Free;
  end;
end;


function TForm1.GeneratePurchaseJSONData(i: Integer): TJSONObject;
var
  MainObj, hacyumst, keikakujwmst, siiredata, keikakumst: TJSONObject;
  SQLCmd: String;
  SQLJson: String;
  JSONData: String;
  SEIZONO: String;
  BUBAN: String;
  KEIKOTEICD: String;
  YMDS: String;
  YMDE:String;
  FormattedYMDS: String;
  FormattedYMDE: String;
  SICD: String;
  SURYO: String;
  TANKA: String;
  KINGAKU: String;
  KMSEQNO, KOTEINO,UPDSEQKEY: Integer;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;

  InputDateFormat: TFormatSettings;

  // GET VALUE FROM SQL Param
  BUCD,BUNM,GKOTEICD : String;
  BUNO,torikbn,GHIMOKUCD : Integer;
begin
  // Create objects for each section
  MainObj := TJSONObject.Create;
  hacyumst := TJSONObject.Create;
  keikakujwmst := TJSONObject.Create;
  siiredata := TJSONObject.Create;
  keikakumst := TJSONObject.Create;

  InputDateFormat := TFormatSettings.Create;  // Optionally pass a locale string here
  InputDateFormat.DateSeparator := '/';
  InputDateFormat.ShortDateFormat := 'yyyy/mm/dd';
  try
    // Get Data from StringGrid with Row Index
    SEIZONO := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Mfg No'), i];
    BUBAN := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Part No'), i];
    KEIKOTEICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Process CD'), i];
    YMDS := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'PO Date'), i];
    YMDE := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Receive Date'), i];
    SICD := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Supplier CD'), i];
    SURYO := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Qty'), i];
    TANKA := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Unit Price'), i];
    KINGAKU := StringGridCSV.Cells[GetColumnIndexByHeaderName(StringGridCSV, 'Total'), i];
    // Format Date for JSON yyyy-mm-dd hh:nn:ss
    FormattedYMDS := FormatDateTime('yyyy-mm-dd hh:nn:ss', StrToDate(YMDS, InputDateFormat));
    FormattedYMDE := FormatDateTime('yyyy-mm-dd hh:nn:ss', StrToDate(YMDE, InputDateFormat));

    // Get KMSEQNO          `
    SQLCmd := 'SELECT KMSEQNO,KOTEINO FROM KEIKAKUMST KM INNER JOIN BUHINKOMST BM ON KM.SEIZONO = BM.SEIZONO AND KM.BUNO = BM.BUNO WHERE KM.SEIZONO = ''' + SEIZONO + ''' AND BM.BUBAN = ''' + BUBAN + ''' AND KM.KEIKOTEICD = ''' + KEIKOTEICD + '''';
    SQLJson := GetSQLJson(SQLCmd);
    JSONArray := TJSONObject.ParseJSONValue(GetDataFromREST(SQLJson)) as TJSONArray;
    JSONObject := JSONArray.Items[0] as TJSONObject;
    JSONObject.TryGetValue<Integer>('kmseqno', KMSEQNO);
    JSONObject.TryGetValue<Integer>('koteino', KOTEINO);

    // Get Insert Value
    SQLCmd := 'SELECT BM.BUNO, KK.torikbn, COALESCE(BM.BUCD,'''') BUCD, ' +
                   'COALESCE(BM.BUNM,'''') BUNM, COALESCE(KK.gkoteicd,'''') gkoteicd, ' +
                   'COALESCE(KG.ghimokucd,0) ghimokucd, KJ.UPDSEQKEY ' +
                   'FROM KEIKAKUMST KM ' +
                   'LEFT JOIN KEIKAKUJWMST KJ ON KM.KMSEQNO = KJ.KMSEQNO ' +
                   'INNER JOIN BUHINKOMST BM ON KM.BUNO = BM.BUNO AND KM.SEIZONO = BM.SEIZONO ' +
                   'INNER JOIN kouteikmst KK ON KM.keikoteicd = KK.keikoteicd ' +
                   'INNER JOIN kouteigmst KG ON KK.gkoteicd = KG.gkoteicd ' +
                   'WHERE KM.KMSEQNO = ' + KMSEQNO.ToString;
    SQLJson := GetSQLJson(SQLCmd);
    JSONArray := TJSONObject.ParseJSONValue(GetDataFromREST(SQLJson)) as TJSONArray;
    JSONObject := JSONArray.Items[0] as TJSONObject;
    JSONObject.TryGetValue<Integer>('buno', BUNO);
    JSONObject.TryGetValue<Integer>('torikbn', TORIKBN);
    JSONObject.TryGetValue<String>('bucd', BUCD);
    JSONObject.TryGetValue<String>('bunm', BUNM);
    JSONObject.TryGetValue<String>('gkoteicd', GKOTEICD);
    JSONObject.TryGetValue<Integer>('ghimokucd', GHIMOKUCD);
    JSONObject.TryGetValue<Integer>('updseqkey', UPDSEQKEY);

    // Populate 'hacyumst' object
    hacyumst.AddPair('hmseqno', TJSONNumber.Create(0));
    hacyumst.AddPair('kmseqno', TJSONNumber.Create(KMSEQNO));
    hacyumst.AddPair('seizono', TJSONString.Create(SEIZONO));
    hacyumst.AddPair('buno', TJSONNumber.Create(BUNO));
    hacyumst.AddPair('torikbn', TJSONNumber.Create(TORIKBN));
    hacyumst.AddPair('bucd', TJSONString.Create(BUCD));
    hacyumst.AddPair('buban', TJSONString.Create(BUBAN));
    hacyumst.AddPair('bunm', TJSONString.Create(BUNM));
    hacyumst.AddPair('buzaicd', TJSONString.Create(''));
    hacyumst.AddPair('buzainm1', TJSONString.Create(''));
    hacyumst.AddPair('buzainm2', TJSONString.Create(''));
    hacyumst.AddPair('keikoteicd', TJSONString.Create(KEIKOTEICD));
    hacyumst.AddPair('gkoteicd', TJSONString.Create(GKOTEICD));
    hacyumst.AddPair('ghimokucd', TJSONNumber.Create(GHIMOKUCD));
    hacyumst.AddPair('furyocd', TJSONString.Create(''));
    hacyumst.AddPair('sicd', TJSONString.Create(SICD));
    hacyumst.AddPair('hacyuymd', TJSONString.Create(FormattedYMDS));
    hacyumst.AddPair('knoukiymd', TJSONString.Create(FormattedYMDE));
    hacyumst.AddPair('hacyusuryo', TJSONNumber.Create(SURYO));
    hacyumst.AddPair('hacyutanka', TJSONNumber.Create(TANKA));
    hacyumst.AddPair('hacyukin', TJSONNumber.Create(KINGAKU));
    hacyumst.AddPair('tani', TJSONString.Create(''));
    hacyumst.AddPair('tanicd', TJSONString.Create(''));
    hacyumst.AddPair('zuban', TJSONString.Create(''));
    hacyumst.AddPair('zaisitu', TJSONString.Create(''));
    hacyumst.AddPair('bikou', TJSONString.Create(''));
    hacyumst.AddPair('koteino', TJSONNumber.Create(KOTEINO));
    hacyumst.AddPair('sagyocd', TJSONString.Create(''));

    // Populate 'keikakujwmst' object
    keikakujwmst.AddPair('kmseqno', TJSONNumber.Create(KMSEQNO));
    keikakujwmst.AddPair('setno', TJSONNumber.Create(0));
    keikakujwmst.AddPair('updseqkey', TJSONNumber.Create(UPDSEQKEY));
    keikakujwmst.AddPair('setseqno', TJSONNumber.Create(0));
    keikakujwmst.AddPair('warikokbn', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jkbn', TJSONNumber.Create(4));
    keikakujwmst.AddPair('jdankbn', TJSONNumber.Create(0));
    keikakujwmst.AddPair('warisuryo', TJSONNumber.Create(SURYO));
    keikakujwmst.AddPair('jsuryo', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jyujinh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jmujinh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jmaedanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jatodanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('yujinzanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('mujinzanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('maedanzanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('atodanzan', TJSONNumber.Create(0));
    keikakujwmst.AddPair('zangyoh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('jnisuu', TJSONNumber.Create(0));
    keikakujwmst.AddPair('zannisuu', TJSONNumber.Create(0));
    keikakujwmst.AddPair('seizono', TJSONString.Create(SEIZONO));
    keikakujwmst.AddPair('wariyujinh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('warimujinh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('warimaedanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('wariatodanh', TJSONNumber.Create(0));
    keikakujwmst.AddPair('wariymds', TJSONString.Create(FormattedYMDS));
    keikakujwmst.AddPair('warikeizokuymds', TJSONString.Create(''));
    keikakujwmst.AddPair('warikeizokuymde', TJSONString.Create(''));
    keikakujwmst.AddPair('warimaedanymde', TJSONString.Create(''));
    keikakujwmst.AddPair('warikikaiymds', TJSONString.Create(''));
    keikakujwmst.AddPair('warikikaiymde', TJSONString.Create(''));
    keikakujwmst.AddPair('wariatodanymds', TJSONString.Create(''));
    keikakujwmst.AddPair('wariymde', TJSONString.Create(''));
    keikakujwmst.AddPair('jymds', TJSONString.Create(YMDS));
    keikakujwmst.AddPair('jkeizokuymds', TJSONString.Create(FormattedYMDE));
    keikakujwmst.AddPair('jkeizokuymde', TJSONString.Create(''));
    keikakujwmst.AddPair('jmaeymde', TJSONString.Create(FormattedYMDE));
    keikakujwmst.AddPair('jkikaiymds', TJSONString.Create(FormattedYMDS));
    keikakujwmst.AddPair('jkikaiymde', TJSONString.Create(FormattedYMDE));
    keikakujwmst.AddPair('jatoymds', TJSONString.Create(FormattedYMDE));
    keikakujwmst.AddPair('jymde', TJSONString.Create(FormattedYMDE));
    keikakujwmst.AddPair('jtantocd', TJSONString.Create(''));
    keikakujwmst.AddPair('jatotantocd', TJSONString.Create(''));
    keikakujwmst.AddPair('furyocd', TJSONString.Create(''));
    keikakujwmst.AddPair('jkikaicd', TJSONString.Create(''));
    keikakujwmst.AddPair('jsicd', TJSONString.Create(SICD));
    keikakujwmst.AddPair('bikou', TJSONString.Create(''));
    keikakujwmst.AddPair('koteino', TJSONNumber.Create(KOTEINO));

    // Populate 'siiredata' object
    siiredata.AddPair('sdseqno', TJSONNumber.Create(0));
    siiredata.AddPair('kmseqno', TJSONNumber.Create(KMSEQNO));
    siiredata.AddPair('seizono', TJSONString.Create(SEIZONO));
    siiredata.AddPair('buno', TJSONNumber.Create(BUNO));
    siiredata.AddPair('torikbn', TJSONNumber.Create(TORIKBN));
    siiredata.AddPair('bucd', TJSONString.Create(BUCD));
    siiredata.AddPair('buban', TJSONString.Create(BUBAN));
    siiredata.AddPair('bunm', TJSONString.Create(BUNM));
    siiredata.AddPair('buzaicd', TJSONString.Create(''));
    siiredata.AddPair('buzainm1', TJSONString.Create(''));
    siiredata.AddPair('buzainm2', TJSONString.Create(''));
    siiredata.AddPair('keikoteicd', TJSONString.Create(KEIKOTEICD));
    siiredata.AddPair('gkoteicd', TJSONString.Create(GKOTEICD));
    siiredata.AddPair('ghimokucd', TJSONNumber.Create(GHIMOKUCD));
    siiredata.AddPair('furyocd', TJSONString.Create(''));
    siiredata.AddPair('sicd', TJSONString.Create(SICD));
    siiredata.AddPair('denpyoymd', TJSONString.Create(FormattedYMDE));
    siiredata.AddPair('kdasiymd', TJSONString.Create(FormattedYMDS));
    siiredata.AddPair('knoukiymd', TJSONString.Create(FormattedYMDE));
    siiredata.AddPair('nyukaymd', TJSONString.Create(FormattedYMDE));
    siiredata.AddPair('keijyoymd', TJSONString.Create(FormattedYMDE));
    siiredata.AddPair('kensyukbn', TJSONNumber.Create(2));
    siiredata.AddPair('nyukakbn', TJSONNumber.Create(0));
    siiredata.AddPair('jyoutaikbn', TJSONNumber.Create(2));
    siiredata.AddPair('jyuuryo', TJSONNumber.Create(0));
    siiredata.AddPair('suryo', TJSONNumber.Create(SURYO));
    siiredata.AddPair('tanka', TJSONNumber.Create(TANKA));
    siiredata.AddPair('kingaku', TJSONNumber.Create(KINGAKU));
    siiredata.AddPair('nisuu', TJSONNumber.Create(0));
    siiredata.AddPair('calckbn', TJSONNumber.Create(0));
    siiredata.AddPair('tani', TJSONString.Create(''));
    siiredata.AddPair('tanicd', TJSONString.Create(''));
    siiredata.AddPair('zuban', TJSONString.Create(''));
    siiredata.AddPair('zuban2', TJSONString.Create(''));
    siiredata.AddPair('zaisitu', TJSONString.Create(''));
    siiredata.AddPair('zaisitucd', TJSONString.Create(''));
    siiredata.AddPair('bikou', TJSONString.Create(''));
    siiredata.AddPair('koteino', TJSONNumber.Create(KOTEINO));
    siiredata.AddPair('inputkbn', TJSONNumber.Create(1));

    // Populate 'keikakumst' object to update Plan data
    keikakumst.AddPair('kmseqno', TJSONNumber.Create(KMSEQNO));
    keikakumst.AddPair('gkoteicd', TJSONString.Create(GKOTEICD));
    keikakumst.AddPair('sicd', TJSONString.Create(SICD));
    keikakumst.AddPair('hacyusuryo', TJSONNumber.Create(SURYO));
    keikakumst.AddPair('hacyutanka', TJSONNumber.Create(TANKA));
    keikakumst.AddPair('hacyukin', TJSONNumber.Create(KINGAKU));

    // Add sub-objects to main object
    MainObj.AddPair('hacyumst', hacyumst);
    MainObj.AddPair('keikakujwmst', keikakujwmst);
    MainObj.AddPair('siiredata', siiredata);
    MainObj.AddPair('keikakumst', keikakumst);

    Result := MainObj;
  finally

  end;
end;

end.
