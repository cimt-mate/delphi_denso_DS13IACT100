unit DatabaseServiceUnit;

interface

uses
  IdHTTP, IdSSLOpenSSL, System.JSON, System.SysUtils, System.Classes, System.NetEncoding;

type
  TDatabaseService = class
  private
    FApiUrl: string;
  public
    function LoginToApi: string;
    function FetchSQLDataFromAPI: TJSONArray;
  end;

implementation

function TDatabaseService.LoginToApi: string;
var
  IdHTTP: TIdHTTP;
  Response: TStringStream;
  RequestBody: TStringStream;
  JsonResponse: TJSONObject;
  SessionID: string;
begin
  Result := '';
  IdHTTP := TIdHTTP.Create(nil);
  Response := TStringStream.Create;
  RequestBody := TStringStream.Create('{"loginID": "admin", "passWord": "admin"}');
  try
    IdHTTP.Request.ContentType := 'application/json';
    IdHTTP.Request.Accept := 'application/json';
    IdHTTP.Post(FApiUrl, RequestBody, Response);
    if IdHTTP.ResponseCode = 200 then
    begin
      JsonResponse := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
      try
        if JsonResponse.TryGetValue<string>('sessionID', SessionID) then
          Result := SessionID;
      finally
        JsonResponse.Free;
      end;
    end;
  finally
    IdHTTP.Free;
    Response.Free;
    RequestBody.Free;
  end;
end;

function TDatabaseService.FetchSQLDataFromAPI: TJSONArray;
var
  IdHTTP: TIdHTTP;
  Response: TStringStream;
  RequestStream: TStringStream;
  JsonResponse: TJSONObject;
  SessionID, JsonStr: string;
begin
  Result := nil;
  SessionID := LoginToApi;
  if SessionID <> '' then
  begin
    IdHTTP := TIdHTTP.Create(nil);
    try
      JsonStr := ''; // Construct your JSON string here
      RequestStream := TStringStream.Create(JsonStr, TEncoding.UTF8);
      try
        Response := TStringStream.Create;
        try
          IdHTTP.Request.ContentType := 'application/json';
          IdHTTP.Request.Accept := 'application/json';
          IdHTTP.Request.CustomHeaders.Values['SESSIONID'] := SessionID;
          IdHTTP.Post(FApiUrl, RequestStream, Response); // Corrected line
          if IdHTTP.ResponseCode = 200 then
          begin
            JsonResponse := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
            try
              // Process JsonResponse as needed
              Result := JsonResponse.Get('data').JsonValue as TJSONArray;
            finally
              JsonResponse.Free;
            end;
          end;
        finally
          Response.Free;
        end;
      finally
        RequestStream.Free;
      end;
    finally
      IdHTTP.Free;
    end;
  end;
end;
end.
