{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{           Oracle Database Connectivity Classes          }
{                                                         }
{        Originally written by Sergey Seroukhov           }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2012 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://sourceforge.net/p/zeoslib/tickets/ (BUGTRACKER)}
{   svn://svn.code.sf.net/p/zeoslib/code-0/trunk (SVN)    }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZDbcOracleStatement;

interface

{$I ZDbc.inc}

uses
  Classes, {$IFDEF MSEgui}mclasses,{$ENDIF} SysUtils, Types, FmtBCD,
  {$IFDEF MSWINDOWS}{%H-}Windows,{$ENDIF}
  {$IFNDEF NO_UNIT_CONTNRS}Contnrs,{$ENDIF}
  ZSysUtils, ZDbcIntfs, ZDbcStatement, ZDbcLogging, ZPlainOracleDriver,
  ZCompatibility, ZVariant, ZDbcOracleUtils, ZPlainOracleConstants,
  ZDbcUtils, ZDbcOracle;

type

  {** Implements a abstract prepared SQL Statement for Oracle }
  TZAbstractOraclePreparedStatement_A = class(TZRawParamDetectPreparedStatement)
  private
    FOCIStmt: POCIStmt;
    FOCIError: POCIError;
    FPlainDriver: TZOraclePlainDriver;
    FOracleConnection: IZOracleConnection;
    FOraVariables: PZOCIParamBinds;
    FRowPrefetchMemory: ub4;
    FZBufferSize: Integer;
    FStatementType: ub2;
    FServerStmtCache: Boolean;
    FCanBindInt64: Boolean;
  protected
    procedure InitBuffer(SQLType: TZSQLType; OCIBind: PZOCIParamBind; Index, ElementCnt: Cardinal; ActualLength: LengthInt = 0);
    function CreateResultSet: IZResultSet;
    procedure SetBindCapacity(Capacity: Integer); override;
    procedure CheckParameterIndex(var Index: Integer); override;
    function GetInParamLogValue(Index: Integer): RawByteString; override;
  protected
    procedure BindBinary(Index: Integer; SQLType: TZSQLType; Buf: Pointer; Len: LengthInt); override;
    procedure BindLob(Index: Integer; SQLType: TZSQLType; const Value: IZBlob); override;
    procedure BindRawStr(Index: Integer; Buf: PAnsiChar; Len: LengthInt); override;
    procedure BindRawStr(Index: Integer; const Value: RawByteString);override;
  public
    constructor Create(const Connection: IZConnection; const SQL: string; Info: TStrings);

    function GetRawEncodedSQL(const SQL: {$IF defined(FPC) and defined(WITH_RAWBYTESTRING)}RawByteString{$ELSE}String{$IFEND}): RawByteString; override;
    procedure RegisterParameter(ParameterIndex: Integer; SQLType: TZSQLType;
      ParamType: TZProcedureColumnType; const Name: String = ''; PrecisionOrSize: LengthInt = 0;
      Scale: LengthInt = 0); override;

    procedure Prepare; override;
    procedure Unprepare; override;

    function ExecuteQueryPrepared: IZResultSet; override;
    function ExecuteUpdatePrepared: Integer; override;
    function ExecutePrepared: Boolean; override;
  end;

  {** Implements Prepared SQL Statement for Oracle }
  TZOraclePreparedStatement_A = class(TZAbstractOraclePreparedStatement_A, IZPreparedStatement)
  private
    procedure BindSInteger(Index: Integer; SQLType: TZSQLType; Value: NativeInt);
    procedure BindUInteger(Index: Integer; SQLType: TZSQLType; Value: NativeUInt);
    procedure InternalBindDouble(Index: Integer; SQLType: TZSQLType; const Value: Double);
  public
    procedure SetNull(Index: Integer; SQLType: TZSQLType);
    procedure SetBoolean(Index: Integer; Value: Boolean);
    procedure SetByte(Index: Integer; Value: Byte);
    procedure SetShort(Index: Integer; Value: ShortInt);
    procedure SetWord(Index: Integer; Value: Word); reintroduce;
    procedure SetSmall(Index: Integer; Value: SmallInt); reintroduce;
    procedure SetUInt(Index: Integer; Value: Cardinal); reintroduce;
    procedure SetInt(Index: Integer; Value: Integer); reintroduce;
    procedure SetULong(Index: Integer; const Value: UInt64); reintroduce;
    procedure SetLong(Index: Integer; const Value: Int64); reintroduce;
    procedure SetFloat(Index: Integer; Value: Single); reintroduce;
    procedure SetDouble(Index: Integer; const Value: Double); reintroduce;
    procedure SetCurrency(Index: Integer; const Value: Currency); reintroduce;
    procedure SetBigDecimal(Index: Integer; const Value: TBCD); reintroduce;

    procedure SetDate(Index: Integer; const Value: TDateTime); reintroduce;
    procedure SetTime(Index: Integer; const Value: TDateTime); reintroduce;
    procedure SetTimestamp(Index: Integer; const Value: TDateTime); reintroduce;

    procedure SetDataArray(ParameterIndex: Integer; const Value; const SQLType: TZSQLType; const VariantType: TZVariantType = vtNull); reintroduce;
    procedure SetNullArray(ParameterIndex: Integer; const SQLType: TZSQLType; const Value; const VariantType: TZVariantType = vtNull); reintroduce;
  end;

  {** Implements SQL Statement for Oracle }
  TZOracleStatement_A = class(TZAbstractOraclePreparedStatement_A, IZStatement)
  public
    constructor Create(const Connection: IZConnection; Info: TStrings);
  end;

  TZOracleCallableStatement_A = class(TZAbstractCallableStatement_A, IZCallableStatement)
  private
    FProcDescriptor: TZOraProcDescriptor_A;
  protected
    function CreateExecutionStatement(Mode: TZCallExecKind; const
      StoredProcName: String): TZAbstractPreparedStatement2; override;
    procedure PrepareInParameters; override;
  public
    procedure Unprepare; override;
  end;

implementation

uses
  Math, {$IFDEF WITH_UNITANSISTRINGS}AnsiStrings, {$ENDIF}
  ZFastCode, ZDbcOracleResultSet, ZTokenizer, ZDbcCachedResultSet,
  ZEncoding, ZDbcProperties, ZMessages, ZClasses, ZDbcResultSet,
  ZSelectSchema;

const
  CommitMode: array[Boolean] of ub4 = (OCI_DEFAULT, OCI_COMMIT_ON_SUCCESS);
  StrGUIDLen = 36;
  SQLType2OCIType: array[stBoolean..stBinaryStream] of ub2 = (
    SQLT_UIN, SQLT_UIN, SQLT_INT, SQLT_UIN, SQLT_INT, SQLT_UIN, SQLT_INT, SQLT_UIN, SQLT_INT,  //ordinals
    SQLT_BFLOAT, SQLT_BDOUBLE, SQLT_VNU, SQLT_VNU, //floats
    SQLT_DAT, SQLT_TIMESTAMP, SQLT_TIMESTAMP, //time values
    SQLT_AFC, //GUID
    SQLT_LVC, SQLT_LVC, SQLT_LVB, //varying size types in equal order
    SQLT_CLOB, SQLT_CLOB, SQLT_BLOB); //lob's
  SQLType2OCISize: array[stBoolean..stBinaryStream] of sb2 = (
    SizeOf(Boolean), SizeOf(Byte), SizeOf(ShortInt), SizeOf(Word), SizeOf(SmallInt), SizeOf(Cardinal), SizeOf(Integer), SizeOf(UInt64), SizeOf(Int64),  //ordinals
    SizeOf(Single), SizeOf(Double), SizeOf(TOCINumber), SizeOf(TOCINumber), //floats
    SizeOf(TOraDate), SizeOf(POCIDescriptor), SizeOf(POCIDescriptor), //time values
    StrGUIDLen, //GUID
    SizeOf(TOCILong), SizeOf(TOCILong), SizeOf(TOCILong),  //varying size types in equal order minimum sizes for 8Byte alignment
    SizeOf(POCIDescriptor), SizeOf(POCIDescriptor), SizeOf(POCIDescriptor)); //lob's
var
  OraPreparableTokens: TPreparablePrefixTokens;

{ TZAbstractOraclePreparedStatement_A }

procedure TZAbstractOraclePreparedStatement_A.BindBinary(Index: Integer;
  SQLType: TZSQLType; Buf: Pointer; Len: LengthInt);
var
  Bind: PZOCIParamBind;
begin
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) then
    SQLType := BindList[Index].SQLType;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.value_sz < Len+SizeOf(Integer)) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1, Len);
  if Bind.dty = SQLT_LVB then begin
    POCILong(Bind.valuep).Len := Len;
    if Buf <> nil then
      Move(Buf^, POCILong(Bind.valuep).data[0], Len);
  end else if Bind.dty = SQLT_AFC then
    GUIDToBuffer(Buf, Bind.valuep, []);
  Bind.indp[0] := 0;
end;

procedure TZAbstractOraclePreparedStatement_A.BindLob(Index: Integer;
  SQLType: TZSQLType; const Value: IZBlob);
var
  Bind: PZOCIParamBind;
  WriteTempBlob: IZOracleBlob;
begin
  Inherited BindLob(Index, SQLType, Value);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if (Value = nil) or Value.IsEmpty then
    Bind.indp[0] := -1
  else begin
    if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
      InitBuffer(SQLType, Bind, Index, 1, SizeOf(POCIDescriptor));
    if Bind.dty = SQLT_BLOB
    then WriteTempBlob := TZOracleBlob.Create(FPlainDriver, nil, 0,
        FOracleConnection.GetServiceContextHandle, FOracleConnection.GetErrorHandle,
        PPOCIDescriptor(Bind^.valuep)^, ChunkSize, ConSettings)
    else WriteTempBlob := TZOracleClob.Create(FPlainDriver, nil, 0,
        FOracleConnection.GetConnectionHandle,
        FOracleConnection.GetServiceContextHandle, FOracleConnection.GetErrorHandle,
        PPOCIDescriptor(Bind^.valuep)^, ChunkSize, ConSettings, ConSettings.ClientCodePage^.CP);
    WriteTempBlob.CreateBlob;
    WriteTempBlob.WriteLobFromBuffer(Value.GetBuffer, Value.Length);
    IZBLob(BindList[Index].Value) := WriteTempBlob;
    Bind.indp[0] := 0;
  end;
end;

procedure TZAbstractOraclePreparedStatement_A.BindRawStr(Index: Integer;
  Buf: PAnsiChar; Len: LengthInt);
var
  Bind: PZOCIParamBind;
  SQLType: TZSQLType;
begin
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType)
  then SQLType := BindList[Index].SQLType
  else SQLType := stString;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.value_sz < Len+SizeOf(Integer)) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1, Len);
  if Bind.dty = SQLT_LVC then begin
    POCILong(Bind.valuep).Len := Len;
    if Buf <> nil then
      Move(Buf^, POCILong(Bind.valuep).data[0], Len);
  end else if Bind.dty = SQLT_CLOB then
    BindLob(Index, stAsciiStream, TZAbstractClob.CreateWithData(Buf, Len, ConSettings^.ClientCodePage^.CP, ConSettings));
  Bind.indp[0] := 0;
end;

procedure TZAbstractOraclePreparedStatement_A.BindRawStr(Index: Integer;
  const Value: RawByteString);
begin
  BindRawStr(Index, Pointer(Value), Length(Value){$IFDEF WITH_TBYTES_AS_RAWBYTESTRING}-1{$ENDIF});
end;

procedure TZAbstractOraclePreparedStatement_A.CheckParameterIndex(var Index: Integer);
begin
  if not Prepared then
    Prepare;
  inherited CheckParameterIndex(Index);
end;

{**
  Constructs this object and assignes the main properties.
  @param Connection a database connection object.
  @param SQL a query to execute.
  @param Info a statement parameters.
}
constructor TZAbstractOraclePreparedStatement_A.Create(
  const Connection: IZConnection; const SQL: string; Info: TStrings);
begin
  inherited Create(Connection, SQL, Info);
  FPlainDriver := TZOraclePlainDriver(Connection.GetIZPlainDriver.GetInstance);
  ResultSetType := rtForwardOnly;
  fOracleConnection := Connection as IZOracleConnection;
  FCanBindInt64 := Connection.GetClientVersion >= 11002000;
  FRowPrefetchMemory := {$IFDEF UNICODE}UnicodeToIntDef{$ELSE}RawToIntDef{$ENDIF}(ZDbcUtils.DefineStatementParameter(Self, DSProps_RowPrefetchSize, ''), 131072);
  FZBufferSize := {$IFDEF UNICODE}UnicodeToIntDef{$ELSE}RawToIntDef{$ENDIF}(ZDbcUtils.DefineStatementParameter(Self, DSProps_InternalBufSize, ''), 131072);
end;

function TZAbstractOraclePreparedStatement_A.CreateResultSet: IZResultSet;
var
  NativeResultSet: IZResultSet;
  CachedResultSet: TZCachedResultSet;
begin
  if FOpenResultSet = nil then begin
    if FStatementType = OCI_STMT_SELECT
    then NativeResultSet := TZOracleResultSet_A.Create(Self, SQL, FOCIStmt, FOCIError, FZBufferSize)
    else NativeResultSet := TZOracleCallableResultSet_A.Create(Self, SQL, FOCIStmt, FOCIError, FOraVariables, BindList);
    if (GetResultSetConcurrency = rcUpdatable) or (GetResultSetType <> rtForwardOnly) then
    begin
      CachedResultSet := TZCachedResultSet.Create(NativeResultSet, SQL, nil, ConSettings);
      if (GetResultSetConcurrency = rcUpdatable) and (FStatementType = OCI_STMT_SELECT) then
        CachedResultSet.SetConcurrency(rcUpdatable);
      CachedResultSet.SetResolver(TZOracleCachedResolver.Create(Self, NativeResultSet.GetMetadata));
      Result := CachedResultSet;
    end else
      Result := NativeResultSet;
    FOpenResultSet := Pointer(Result);
  end else
    Result := IZResultSet(FOpenResultSet);
end;

{**
  Executes the SQL query in this <code>PreparedStatement</code> object
  and returns the result set generated by the query.

  @return a <code>ResultSet</code> object that contains the data produced by the
    query; never <code>null</code>
}
function TZAbstractOraclePreparedStatement_A.ExecutePrepared: Boolean;
var
  Status: sword;
  upCnt: ub4;
begin
  Result := False;
  PrepareLastResultSetForReUse;
  { Prepares a statement. }
  Prepare;
  { logs the values }
  BindInParameters;

  if (FStatementType = OCI_STMT_SELECT) then begin
    { Executes the statement and gets a resultset. }
    if not Assigned(LastResultSet) then
      LastResultSet := CreateResultSet;
    Result := LastResultSet <> nil;
  end else begin
    { Executes the statement and gets a result. }
    Status := FPlainDriver.OCIStmtExecute(FOracleConnection.GetServiceContextHandle,
        FOCIStmt, FOCIError, Max(1, BatchDMLArrayCount), 0, nil, nil, CommitMode[Connection.GetAutoCommit]);
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, status, lcExecute, ASQL, ConSettings);
    Status := FPlainDriver.OCIAttrGet(FOCIStmt, OCI_HTYPE_STMT, @upCnt, nil,
      OCI_ATTR_ROW_COUNT, FOCIError);
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, status, lcExecute, ASQL, ConSettings);
    LastUpdateCount := upCnt;
    if (FStatementType = OCI_STMT_BEGIN) and (BindList.HasOutOrInOutOrResultParam) then
      FOutParamResultSet := CreateResultSet;
  end;
  inherited ExecutePrepared;
end;

{**
  Executes the SQL query in this <code>PreparedStatement</code> object
  and returns the result set generated by the query.

  @return a <code>ResultSet</code> object that contains the data produced by the
    query; never <code>null</code>
}
function TZAbstractOraclePreparedStatement_A.ExecuteQueryPrepared: IZResultSet;
var
  Status: sword;
  upCnt: ub4;
begin
  PrepareOpenResultSetForReUse;
  { Prepares a statement. }
  Prepare;
  //log values
  if DriverManager.HasLoggingListener then
    DriverManager.LogMessage(lcBindPrepStmt,Self);

  { Executes the statement and gets a resultset. }
  if (FStatementType = OCI_STMT_BEGIN) and (BindList.HasOutOrInOutOrResultParam) then begin
    Status := FPlainDriver.OCIStmtExecute(FOracleConnection.GetServiceContextHandle,
        FOCIStmt, FOCIError, Max(1, BatchDMLArrayCount), 0, nil, nil, CommitMode[Connection.GetAutoCommit]);
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, status, lcExecute, ASQL, ConSettings);
    FPlainDriver.OCIAttrGet(FOCIStmt, OCI_HTYPE_STMT, @upCnt, nil, OCI_ATTR_ROW_COUNT, FOCIError);
    LastUpdateCount := upCnt;
    Result := CreateResultSet;
    FOutParamResultSet := Result;
  end else if (FStatementType = OCI_STMT_SELECT)  then
    Result := CreateResultSet
  else begin
    Result := nil; //satisfy compiler
    raise EZSQLException.Create(SCanNotRetrieveResultSetData);
  end;
  { Logging Execution }
  if DriverManager.HasLoggingListener then
    DriverManager.LogMessage(lcExecPrepStmt,Self);
end;

{**
  Executes the SQL INSERT, UPDATE or DELETE statement
  in this <code>PreparedStatement</code> object.
  In addition,
  SQL statements that return nothing, such as SQL DDL statements,
  can be executed.

  @return either the row count for INSERT, UPDATE or DELETE statements;
  or 0 for SQL statements that return nothing
}
function TZAbstractOraclePreparedStatement_A.ExecuteUpdatePrepared: Integer;
var
  ResultSet: IZResultSet;
  Status: sword;
  upCnt: ub4;
begin
  { Prepares a statement. }
  Prepare;

  if FOpenResultSet <> nil then
  begin
    IZResultSet(FOpenResultSet).Close;
    FOpenResultSet := nil;
  end;

  if DriverManager.HasLoggingListener then
    DriverManager.LogMessage(lcBindPrepStmt,Self);
  if (FStatementType = OCI_STMT_SELECT) then begin
    LastUpdateCount := -1;
    { Executes the statement and gets a resultset. }
    ResultSet := CreateResultSet;
    try
      while ResultSet.Next do;
      LastUpdateCount := ResultSet.GetRow;
    finally
      ResultSet.Close;
    end;
  end else begin
    { Executes the statement and gets a result. }
    Status := FPlainDriver.OCIStmtExecute(FOracleConnection.GetServiceContextHandle,
        FOCIStmt, FOCIError, Max(1, BatchDMLArrayCount), 0, nil, nil, CommitMode[Connection.GetAutoCommit]);
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, status, lcExecute, ASQL, ConSettings);
    FPlainDriver.OCIAttrGet(FOCIStmt, OCI_HTYPE_STMT, @upCnt, nil, OCI_ATTR_ROW_COUNT, FOCIError);
    LastUpdateCount := upCnt;
    if (FStatementType = OCI_STMT_BEGIN) and (BindList.HasOutOrInOutOrResultParam) then
      FOutParamResultSet := CreateResultSet;
  end;
  Result := LastUpdateCount;
  { logging execution }
  if DriverManager.HasLoggingListener then
    DriverManager.LogMessage(lcExecPrepStmt,Self);
end;

function TZAbstractOraclePreparedStatement_A.GetInParamLogValue(
  Index: Integer): RawByteString;
var
  Bind: PZOCIParamBind;
  TS: TZTimeStamp;
begin
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Bind.curelen > 1 then
    Result := '(Array)'
  else if Bind.indp[0] = -1 then
    Result := 'null'
  else case Bind.dty of
    SQLT_INT: if Bind.value_sz = SizeOf(Int64) then
                Result := IntToRaw(PInt64(Bind.valuep)^)
              else if Bind.value_sz = SizeOf(Integer) then
                Result := IntToRaw(PInteger(Bind.valuep)^)
              else
                Result := IntToRaw(PSmallInt(Bind.valuep)^);
    SQLT_UIN: if Bind.value_sz = SizeOf(UInt64) then
                Result := IntToRaw(PUInt64(Bind.valuep)^)
              else if Bind.value_sz = SizeOf(Cardinal) then
                Result := IntToRaw(PCardinal(Bind.valuep)^)
              else
                Result := IntToRaw(PWord(Bind.valuep)^);
    SQLT_BFLOAT: Result := FloatToSqlRaw(PSingle(Bind.valuep)^);
    SQLT_BDOUBLE: Result := FloatToSqlRaw(PDouble(Bind.valuep)^);
    SQLT_DAT: Result := DateTimeToRawSQLDate(EncodeDate((POraDate(Bind.valuep).Cent-100)*100+(POraDate(Bind.valuep).Year-100),
      POraDate(Bind.valuep).Month,POraDate(Bind.valuep).Day), ConSettings.DisplayFormatSettings, True);
    SQLT_TIMESTAMP: begin
            FPlainDriver.OCIDateTimeGetDate(FOracleConnection.GetConnectionHandle, FOCIError,
              PPOCIDescriptor(Bind.valuep)^, PSB2(@TS.Year)^, PUB1(@TS.Month)^, PUB1(@Ts.Day)^);
            FPlainDriver.OCIDateTimeGetTime(FOracleConnection.GetConnectionHandle, FOCIError,
              PPOCIDescriptor(Bind.valuep)^, PUB1(@Ts.Hour)^, PUB1(@Ts.Minute)^, PUB1(@Ts.Second)^, Ts.Fractions);
            Result := DateTimeToRawSQLTimeStamp(EncodeDate(PSB2(@TS.Year)^, PUB1(@TS.Month)^, PUB1(@Ts.Day)^)+
              EncodeTime(PUB1(@Ts.Hour)^, PUB1(@Ts.Minute)^, PUB1(@Ts.Second)^, Ts.Fractions div 1000000), ConSettings.DisplayFormatSettings, True);
      end;
    SQLT_AFC: Result := SQLQuotedStr(Bind.valuep, Bind.Value_sz, AnsiChar(#39));
    SQLT_VCS: ZSetString(@POCIVary(Bind.valuep).data[0], POCIVary(Bind.valuep).Len, Result); //used for big (s/u) ordinals on old oracle
    SQLT_LVC: Result := SQLQuotedStr(PAnsiChar(@POCILong(Bind.valuep).data[0]), POCILong(Bind.valuep).Len, AnsiChar(#39));
    SQLT_LVB: Result := GetSQLHexAnsiString(@POCILong(Bind.valuep).data[0], POCILong(Bind.valuep).Len, False);
    SQLT_CLOB: Result := '(CLOB)';
    SQLT_BLOB: Result := '(BLOB)';
    else Result := 'unknown'
  end;
end;

function TZAbstractOraclePreparedStatement_A.GetRawEncodedSQL(
  const SQL: {$IF defined(FPC) and defined(WITH_RAWBYTESTRING)}RawByteString{$ELSE}String{$IFEND}): RawByteString;
var
  I, C, N, FirstComposePos, ParamsCnt: Integer;
  Tokens: TZTokenList;
  Token: PZToken;
  {$IFNDEF UNICODE}
  tmp: RawByteString;
  List: TStrings;
  {$ENDIF}
  ComparePrefixTokens: TPreparablePrefixTokens;
  procedure Add(const Value: RawByteString; const Param: Boolean = False);
  begin
    SetLength(FCachedQueryRaw, Length(FCachedQueryRaw)+1);
    FCachedQueryRaw[High(FCachedQueryRaw)] := Value;
    SetLength(FIsParamIndex, Length(FCachedQueryRaw));
    FIsParamIndex[High(FIsParamIndex)] := Param;
    ToBuff(Value, Result);
  end;
  function IsNumeric(P, PEnd: PChar): Boolean;
  begin
    Result := P<= PEnd;
    repeat
      Result := Result and ((Ord(P^) >= Ord('0')) and (Ord(P^) <= Ord('9')));
      if not Result
      then Break
      else Inc(P);
    until P > PEnd;
  end;
begin
  Result := '';
  if (Length(FCachedQueryRaw) = 0) and (SQL <> '') then begin
    Tokens := Connection.GetDriver.GetTokenizer.TokenizeBufferToList(SQL, [toSkipEOF]);
    {$IFNDEF UNICODE}
    if ConSettings.AutoEncode
    then List := TStringList.Create
    else List := nil; //satisfy comiler
    {$ENDIF}
    try
      ComparePrefixTokens := OraPreparableTokens;
      N := -1;
      FTokenMatchIndex := -1;
      ParamsCnt := 0;
      FirstComposePos := 0;
      for I := 0 to Tokens.Count -1 do begin
        Token := Tokens[I];
        {check if we've a preparable statement. If ComparePrefixTokens = nil then
          comparing is not required or already done }
        if Assigned(ComparePrefixTokens) and (Token.TokenType = ttWord) then
          if N = -1 then begin
            for C := 0 to high(ComparePrefixTokens) do
              if Tokens.IsEqual(i, ComparePrefixTokens[C].MatchingGroup, tcInsensitive) then begin
                if Length(ComparePrefixTokens[C].ChildMatches) = 0 then begin
                  FTokenMatchIndex := C;
                  ComparePrefixTokens := nil;
                end else
                  N := C; //save group
                Break;
              end;
            if N = -1 then //no sub-tokens ?
              ComparePrefixTokens := nil; //stop compare sequence
          end else begin //we already got a group
            FTokenMatchIndex := -1;
            for C := 0 to high(ComparePrefixTokens[N].ChildMatches) do
              if Tokens.IsEqual(i, ComparePrefixTokens[N].ChildMatches[C], tcInsensitive) then begin
                FTokenMatchIndex := N;
                Break;
              end;
            ComparePrefixTokens := nil; //stop compare sequence
          end;
        if ((Token.P^ = '?') and (Token.L = 1)) or
           ((Token.TokenType = ttWord) and (Token.P^ = ':') and (Token.L > 2) and
           (Ord((Token.P+1)^) or $20 = Ord('p')){lowercase 'P'} and IsNumeric(Token.P+2, Token.P+Token.L-2)) then begin
          Inc(ParamsCnt);
          {$IFDEF UNICODE}
          Add(ZUnicodeToRaw(Tokens.AsString(FirstComposePos, I-1), ConSettings^.ClientCodePage^.CP));
          if (Token.P^ = '?')
          then Add(':P'+IntToRaw(ParamsCnt), True)
          else Add(UnicodeStringToAscii7(Token.P, Token.L), True);
          {$ELSE}
          Add(Tokens.AsString(FirstComposePos, I-1));
          if (Token.P^ = '?')
          then Add(':P'+IntToRaw(ParamsCnt), True)
          else Add(TokenAsString(Token^), True);
          {$ENDIF}
          FirstComposePos := i + 1;
        end {$IFNDEF UNICODE}
        else if ConSettings.AutoEncode then
          case (Token.TokenType) of
            ttQuoted, ttComment,
            ttWord, ttQuotedIdentifier: begin
              tmp := ConSettings^.ConvFuncs.ZStringToRaw(TokenAsString(Token^), ConSettings^.CTRL_CP, ConSettings^.ClientCodePage^.CP);
              Token^.P := Pointer(tmp);
              Token^.L := Length(tmp);
              List.Add(tmp); //keep alive
            end;
        end
        {$ENDIF};
      end;
      if (FirstComposePos <= Tokens.Count-1) then
        Add(ConSettings^.ConvFuncs.ZStringToRaw(Tokens.AsString(FirstComposePos, Tokens.Count -1), ConSettings^.CTRL_CP, ConSettings^.ClientCodePage^.CP));
      SetBindCapacity(ParamsCnt);
      FServerStmtCache := (FTokenMatchIndex > -1) and (FTokenMatchIndex < OCI_STMT_CREATE) and (ParamsCnt > 0);
    finally
      FlushBuff(Result);
      Tokens.Free;
      {$IFNDEF UNICODE}
      if ConSettings.AutoEncode then
        List.Free;
      {$ENDIF}
    end;
  end else
    Result := ASQL;
end;
{$IFDEF NEXTGEN}{$HINTS OFF}{$ENDIF}//wrong hint OldSize assigned value is never used
procedure TZAbstractOraclePreparedStatement_A.InitBuffer(SQLType: TZSQLType;
  OCIBind: PZOCIParamBind; Index, ElementCnt: Cardinal; ActualLength: LengthInt);
var
  Status: sword;
  I, OldSize: Integer;
begin
  { free Desciptors }
  if (OCIBind.DescriptorType <> 0) then begin
    if (OCIBind.DescriptorType <> SQLType2OCIDescriptor[SQLType]) then
      OldSize := 0
    else if (OCIBind.DescriptorType = SQLType2OCIDescriptor[SQLType]) and (ElementCnt < OCIBind.curelen) then
      OldSize := ElementCnt
    else OldSize := OCIBind.curelen;
    for I := OCIBind.curelen-1 downto OldSize do begin
      Status := FPlainDriver.OCIDescriptorFree(PPOCIDescriptor(PAnsiChar(OCIBind.valuep)+I*SizeOf(POCIDescriptor))^, OCIBind.DescriptorType);
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcExecute, ASQL, ConSettings);
    end;
  end;

  OCIBind.DescriptorType := SQLType2OCIDescriptor[SQLType];
  OCIBind.dty := SQLType2OCIType[SQLType];

  OldSize := OCIBind.value_sz;
  {check if the parameter type was registered before -> they should be valid only }
  if (BindList[Index].ParamType <> pctUnknown) and (SQLType <> BindList[Index].SQLType) then
    raise EZSQLException.Create(SUnKnownParamDataType);
  if (SQLType in [stLong, stULong]) and not FCanBindInt64 then begin
    OCIBind.dty := SQLT_VNU;
    OCIBind.value_sz := SizeOf(TOCINumber);
  end else if SQLType in [stString, stUnicodeString, stBytes] then { 8 byte aligned buffer -> }
    OCIBind.value_sz := Max((((Max(Max(OCIBind.Precision, ActualLength)+SizeOf(Sb4), SQLType2OCISize[SQLType])-1) shr 3)+1) shl 3, OCIBind.value_sz)
  else OCIBind.value_sz := SQLType2OCISize[SQLType];

  if ElementCnt = 1 then
    BindList[Index].SQLType := SQLType;
  { allocmem for the null indicators }
  if OCIBind.curelen <> ElementCnt then begin
    if OCIBind.indp <> nil then
      FreeMem(OCIBind.indp, OCIBind.curelen*SizeOf(SB2));
    GetMem(OCIBind.indp, SizeOf(SB2)*ElementCnt); //alloc mem for indicators
  end;
  //alloc buffer space
  if (OCIBind.DescriptorType <> 0) then begin
    ReallocMem(OCIBind.valuep, OCIBind.value_sz*Integer(ElementCnt));
    for I := OCIBind.curelen to ElementCnt -1 do begin
      { allocate lob/time oci descriptors }
      Status := FPlainDriver.OCIDescriptorAlloc(FOracleConnection.GetConnectionHandle,
          PPOCIDescriptor(OCIBind.valuep+I*SizeOf(POCIDescriptor))^, OCIBind.DescriptorType, 0, nil);
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcExecute, ASQL, ConSettings);
    end;
  end else begin
    if OCIBind.valuep <> nil then begin
      FreeMem(OCIBind.valuep, OldSize*Integer(OCIBind.curelen));
      OCIBind.valuep := nil;
    end;
    if (not ((ElementCnt > 1) and (Ord(SQLType) < Ord(stCurrency)) and (OCIBind.dty <> SQLT_VNU) )) then
      GetMem(OCIBind.valuep, OCIBind.value_sz*Integer(ElementCnt));
  end;
  OCIBind.curelen := ElementCnt;
  { in array bindings we directly OCIBind the pointer of the dyn arrays instead of moving data}
  if OCIBind.valuep <> nil then begin
    Status := FPlainDriver.OCIBindByPos(FOCIStmt, OCIBind.bindpp, FOCIError, Index + 1,
      OCIBind.valuep, OCIBind.value_sz, OCIBind.dty, OCIBind.indp, nil, nil, 0, nil, OCI_DEFAULT);
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, Status, lcExecute, ASQL, ConSettings);
  end;
end;
{$IFDEF NEXTGEN}{$HINTS ON}{$ENDIF}//wrong hint OldSize assigned value is never used

{**
  prepares the statement on the server if minimum execution
  count have been reached
}
procedure TZAbstractOraclePreparedStatement_A.Prepare;
var
  Status: sword;
  Prefetch: ub4;
begin
  if not Prepared then begin
    // we need a errorhandle per stmt
    if (FOCIError = nil) then begin
      Status := FPlainDriver.OCIHandleAlloc(FOracleConnection.GetConnectionHandle,
        FOCIError, OCI_HTYPE_ERROR, 0, nil);
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCIHandleAlloc(OCIError-Handle)', ConSettings);
    end;

    if (FOCIStmt = nil) then begin
      if FServerStmtCache then begin
        //check if query is found in the server cache
        Status := FPlainDriver.OCIStmtPrepare2(FOracleConnection.GetServiceContextHandle,
          FOCIStmt, FOCIError, Pointer(FASQL), Length(FASQL)+1,nil,0,OCI_NTV_SYNTAX,
            OCI_PREP2_CACHE_SEARCHONLY);
        if Status <> OCI_SUCCESS then //not found! Create new handle in server cache
          Status := FPlainDriver.OCIStmtPrepare2(FOracleConnection.GetServiceContextHandle,
            FOCIStmt, FOCIError, Pointer(FASQL), Length(FASQL)+1,nil,0,OCI_NTV_SYNTAX,
              OCI_DEFAULT);
      end else begin
        Status := FPlainDriver.OCIHandleAlloc(FOracleConnection.GetConnectionHandle,
          FOCIStmt, OCI_HTYPE_STMT, 0, nil);
        if Status <> OCI_SUCCESS then
          CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCIHandleAlloc(OCIStmt-Handle)', ConSettings);
        Status := FPlainDriver.OCIStmtPrepare(FOCIStmt, FOCIError, Pointer(FASQL),
          Length(FASQL)+1, OCI_NTV_SYNTAX, OCI_DEFAULT);
      end;
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcPrepStmt, 'prepare statement', ConSettings);
    end;
    { get statement type }
    Status := FPlainDriver.OCIAttrGet(FOCIStmt, OCI_HTYPE_STMT, @FStatementType,
      nil, OCI_ATTR_STMT_TYPE, FOCIError);
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCIAttrGet(OCI_ATTR_STMT_TYPE)', ConSettings);
    if FStatementType = OCI_STMT_SELECT then begin
      //set prefetch by memory! not by Rows!
      Prefetch := 0;
      Status := FPlainDriver.OCIAttrSet(FOCIStmt,OCI_HTYPE_STMT, @Prefetch ,0, OCI_ATTR_PREFETCH_ROWS,FOCIError);
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCIAttrSet(OCI_ATTR_PREFETCH_ROWS)', ConSettings);
      Prefetch := FRowPrefetchMemory;
      Status := FPlainDriver.OCIAttrSet(FOCIStmt,OCI_HTYPE_STMT,@Prefetch,0,OCI_ATTR_PREFETCH_MEMORY,FOCIError);
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCIAttrSet(OCI_ATTR_PREFETCH_MEMORY)', ConSettings);
    end;
    inherited Prepare;
  end;
end;

procedure TZAbstractOraclePreparedStatement_A.RegisterParameter(
  ParameterIndex: Integer; SQLType: TZSQLType; ParamType: TZProcedureColumnType;
  const Name: String; PrecisionOrSize, Scale: LengthInt);
var
  Bind: PZOCIParamBind;
begin
  if SQLType in [stUnicodeString, stUnicodeStream] then
    SQLType := TZSQLType(Ord(SQLType)-1);
  CheckParameterIndex(ParameterIndex);
  inherited RegisterParameter(ParameterIndex, SQLType, ParamType, Name,
    PrecisionOrSize, Scale);
  {$R-}
  Bind := @FOraVariables[ParameterIndex];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  Bind.Precision := PrecisionOrSize;
  Bind.Scale := Scale;
  Bind.ParamName := Name;
  if ParamType <> pctUnknown then begin
    if (Scale > 0) and (SQLType in [stBoolean..stBigDecimal]) then
      SQLType := stBigDecimal;
    if (BindList[ParameterIndex].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then begin
      InitBuffer(SQLType, Bind, ParameterIndex, 1, PrecisionOrSize);
      FillChar(Bind.valuep^, Bind.Value_sz, #0);
    end;
    Bind.indp[0] := -1;
  end;
end;

{**
  Sets a new parameter capacity and initializes the buffers.
  @param NewParamCount a new parameters count.
}
procedure TZAbstractOraclePreparedStatement_A.SetBindCapacity(Capacity: Integer);
var
  OldCapacity, I, J: Integer;
  Bind: PZOCIParamBind;
begin
  OldCapacity := BindList.Capacity;
  inherited SetBindCapacity(Capacity);
  if OldCapacity <> Capacity then begin
    for I := OldCapacity-1 downto Capacity do begin
      {$R-}
      Bind := @FOraVariables[I];
      {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
      Bind.ParamName := '';
      if Bind.DescriptorType <> 0 then //deallocate the descriptors
        for J := 0 to Bind.curelen-1 do
          FPlainDriver.OCIDescriptorFree(PPOCIDescriptor(PAnsiChar(Bind.valuep)+J*SizeOf(POCIDescriptor))^, Bind.DescriptorType);
      if Bind.valuep <> nil then
        FreeMem(Bind.valuep, Bind.value_sz*Integer(Bind.curelen));
      if Bind.indp <> nil then
        FreeMem(Bind.indp, SizeOf(SB2)*Bind.curelen);
    end;
    ReallocMem(FOraVariables, Capacity * SizeOf(TZOCIParamBind));
    if FOraVariables <> nil then
      FillChar((PAnsichar(FOraVariables)+(OldCapacity*SizeOf(TZOCIParamBind)))^,
        (Capacity-OldCapacity)*SizeOf(TZOCIParamBind), {$IFDEF Use_FastCodeFillChar}#0{$ELSE}0{$ENDIF});
  end;
end;

procedure TZAbstractOraclePreparedStatement_A.Unprepare;
var Status: sword;
begin
  try
    inherited Unprepare;
  finally
    if FOCIStmt <> nil then begin
      if FServerStmtCache
      then Status := FPlainDriver.OCIStmtRelease(FOCIStmt, FOCIError, nil, 0, OCI_STMTCACHE_DELETE)
      else Status := FPlainDriver.OCIHandleFree(FOCIStmt, OCI_HTYPE_STMT);
      FOCIStmt := nil;
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcUnprepStmt, ASQL, ConSettings)
    end;
    if FOCIError <> nil then begin
      Status := FPlainDriver.OCIHandleFree(FOCIError, OCI_HTYPE_ERROR);
      FOCIError := nil;
      if Status <> OCI_SUCCESS then
        CheckOracleError(FPlainDriver, FOCIError, Status, lcExecute, ASQL, ConSettings)
    end;
  end;
end;

{ TZOracleStatement_A }

constructor TZOracleStatement_A.Create(const Connection: IZConnection;
  Info: TStrings);
begin
  inherited Create(Connection, '', Info);
end;

{ TZOracleCallableStatement_A }

function TZOracleCallableStatement_A.CreateExecutionStatement(
  Mode: TZCallExecKind;
  const StoredProcName: String): TZAbstractPreparedStatement2;
var
  ProcSQL: {$IFDEF UNICODE}String{$ELSE}RawByteString{$ENDIF};
  Buf: {$IFDEF UNICODE}TUCS2Buff{$ELSE}TRawBuff{$ENDIF};
  IC: IZIdentifierConvertor;

  procedure AddArgs({$IFDEF AUTOREFCOUNT}const{$ENDIF}Params: TObjectList);
  var I: Integer;
  begin
    ZDbcUtils.ToBuff('(', Buf, ProcSQL);
    for I := 0 to Params.Count-1 do
      if TZOraProcDescriptor_A(Params[i]).OrdPos > 0 then begin
        ZDbcUtils.ToBuff(':', Buf, ProcSQL);
        TZOraProcDescriptor_A(Params[i]).ConcatParentName(False, buf, ProcSQL, IC);
        ZDbcUtils.ToBuff(TZOraProcDescriptor_A(Params[i]).AttributeName, Buf, ProcSQL);
        ZDbcUtils.ToBuff(',', Buf, ProcSQL);
      end;
    ReplaceOrAddLastChar(',',')',Buf,ProcSQL);
  end;

  procedure BuildFunction({$IFDEF AUTOREFCOUNT}const{$ENDIF}Descriptor: TZOraProcDescriptor_A);
  begin
    ZDbcUtils.ToBuff(':', Buf, ProcSQL);
    TZOraProcDescriptor_A(Descriptor.Args[0]).ConcatParentName(False, buf, ProcSQL, IC);
    ZDbcUtils.ToBuff(TZOraProcDescriptor_A(Descriptor.Args[0]).AttributeName, Buf, ProcSQL);
    ZDbcUtils.ToBuff(' := ', Buf, ProcSQL);
    Descriptor.ConcatParentName(True, Buf, ProcSQL, IC);
    ZDbcUtils.ToBuff(IC.Quote(Descriptor.AttributeName), Buf, ProcSQL);
    AddArgs(Descriptor.Args);
    ZDbcUtils.ToBuff(';', Buf, ProcSQL);
  end;
  procedure BuildProcedure({$IFDEF AUTOREFCOUNT}const{$ENDIF}Descriptor: TZOraProcDescriptor_A);
  begin
    Descriptor.ConcatParentName(True, Buf, ProcSQL, IC);
    ZDbcUtils.ToBuff(IC.Quote(Descriptor.AttributeName), Buf, ProcSQL);
    AddArgs(Descriptor.Args);
    ZDbcUtils.ToBuff(';', Buf, ProcSQL);
  end;
  procedure BuildPackage({$IFDEF AUTOREFCOUNT}const{$ENDIF}Descriptor: TZOraProcDescriptor_A);
  var I: Integer;
  begin
    for I := 0 to Descriptor.Args.Count -1 do begin
      if Descriptor.Parent <> nil then
        ZDbcUtils.ToBuff('BEGIN'#10, Buf, ProcSQL);
      if TZOraProcDescriptor_A(Descriptor.Args[I]).ObjType = OCI_PTYPE_PKG then
        BuildPackage(TZOraProcDescriptor_A(Descriptor.Args[I]))
      else if TZOraProcDescriptor_A(Descriptor.Args[I]).ObjType = OCI_PTYPE_PROC then
        BuildProcedure(TZOraProcDescriptor_A(Descriptor.Args[I]))
      else if TZOraProcDescriptor_A(Descriptor.Args[I]).ObjType = OCI_PTYPE_FUNC then
        BuildFunction(TZOraProcDescriptor_A(Descriptor.Args[I]))
      else
        AddArgs(Descriptor.Args);
      if Descriptor.Parent <> nil then
        ZDbcUtils.ToBuff(#10'END;', Buf, ProcSQL);
    end;
  end;
begin
  IC := Connection.GetMetadata.GetIdentifierConvertor;
  if FProcDescriptor = nil then
    { describe the object: }
    FProcDescriptor := TZOraProcDescriptor_A.Create(nil);
  if FProcDescriptor.ObjType = OCI_PTYPE_UNK then
    FProcDescriptor.Describe(OCI_PTYPE_UNK, Connection, StoredProcName);
  ProcSQL := '';
  Buf.Pos := 0;
  ZDbcUtils.ToBuff('BEGIN'#10, Buf, ProcSQL);
  if FProcDescriptor.ObjType = OCI_PTYPE_PKG then
    BuildPackage(FProcDescriptor)
  else if FProcDescriptor.ObjType = OCI_PTYPE_PROC then
    BuildProcedure(FProcDescriptor)
  else
    BuildFunction(FProcDescriptor);
  ZDbcUtils.ToBuff(#10'END;', Buf, ProcSQL);
  ZDbcUtils.FlushBuff(Buf,ProcSQL);
  Result := TZOraclePreparedStatement_A.Create(Connection, '', Info);
  TZOraclePreparedStatement_A(Result).FASQL := {$IFDEF UNICODE}ZUnicodeToRaw(ProcSQL, FClientCP){$ELSE}ProcSQL{$ENDIF};
  TZOraclePreparedStatement_A(Result).Prepare;
  FExecStatements[TZCallExecKind(not Ord(Mode) and 1)] := Result;
  TZOraclePreparedStatement_A(Result)._AddRef;
end;

const OCIParamTypeMatrix: array[boolean] of array[OCI_TYPEPARAM_IN..OCI_TYPEPARAM_INOUT] of TZProcedureColumnType =
  ((pctIn, pctOut, pctInOut),(pctReturn,pctReturn,pctReturn));
procedure TZOracleCallableStatement_A.PrepareInParameters;
var Idx: Integer;
  procedure RegisterFromDescriptor(ParentDescriptor: TZOraProcDescriptor_A;
    var IDX: Integer);
  var i: Integer;
    Descriptor: TZOraProcDescriptor_A;
    Tmp: {$IFDEF UNICODE}String{$ELSE}RawByteString{$ENDIF};
    Buf: {$IFDEF UNICODE}TUCS2Buff{$ELSE}TRawBuff{$ENDIF};
  begin
    for I := 0 to ParentDescriptor.Args.Count-1 do begin
      Descriptor := TZOraProcDescriptor_A(ParentDescriptor.Args[i]);
      if Descriptor.ObjType <> OCI_PTYPE_ARG then
        RegisterFromDescriptor(Descriptor, IDX)
      else begin
        Tmp := '';
        Buf.Pos := 0;
        Descriptor.ConcatParentName(False, Buf, Tmp, nil);
        ZDbcUtils.ToBuff(Descriptor.AttributeName, Buf, Tmp);
        ZDbcUtils.FlushBuff(Buf,tmp);
        if FExecStatements[FCallExecKind] = nil then
          RegisterParameter(IDX,
            Descriptor.SQLType, OCIParamTypeMatrix[Descriptor.OrdPos = 0][Descriptor.IODirection], tmp,
              Max(Descriptor.DataSize, Descriptor.Precision), Descriptor.Scale)
        else
          FExecStatements[FCallExecKind].RegisterParameter(IDX,
            Descriptor.SQLType, OCIParamTypeMatrix[Descriptor.OrdPos = 0][Descriptor.IODirection], tmp,
              Max(Descriptor.DataSize, Descriptor.Precision), Descriptor.Scale);
        Inc(IDX);
      end;
    end;
  end;
begin
  if not FParamsRegistered then begin
    FParamsRegistered := True;
    FRegisteringParamFromMetadata := True;
    if FProcDescriptor = nil then
      FProcDescriptor := TZOraProcDescriptor_A.Create(nil);
    if FProcDescriptor.ObjType = OCI_PTYPE_UNK then
      { describe the object: }
      FProcDescriptor.Describe(OCI_PTYPE_UNK, Connection, StoredProcName);
    if FProcDescriptor <> nil then begin
      Idx := 0;
      RegisterFromDescriptor(FProcDescriptor, IDX);
    end;
    FRegisteringParamFromMetadata := False;
  end;
end;

procedure TZOracleCallableStatement_A.Unprepare;
begin
  inherited Unprepare;
  if FProcDescriptor <> nil then
    FreeAndNil(FProcDescriptor);
end;

{ TZOraclePreparedStatement_A }

{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R-}{$IFEND}
procedure TZOraclePreparedStatement_A.BindSInteger(Index: Integer;
  SQLType: TZSQLType; Value: NativeInt);
var
  Bind: PZOCIParamBind;
  P: PAnsiChar;
  Status: sword;
begin
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IF defined (RangeCheckEnabled) and not defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) and
     (SQLType <> BindList[Index].SQLType) then //keep registered types alive
    SQLType := BindList[Index].SQLType;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  case Bind.dty of
    SQLT_VNU: begin
        Status := FPlainDriver.OCINumberFromInt(FOCIError, @Value, SizeOf(NativeInt), OCI_NUMBER_SIGNED, POCINumber(Bind.valuep));
        if Status <> OCI_SUCCESS then
          CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCINumberFromInt', ConSettings);
      end;
    SQLT_INT: if Bind.value_sz = SizeOf(Int64) then
                PInt64(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Integer) then
                PInteger(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(SmallInt) then
                PSmallInt(Bind.valuep)^ := Value
              else
                PShortInt(Bind.valuep)^ := Value;
    SQLT_UIN: if Bind.value_sz = SizeOf(UInt64) then
                PUInt64(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Cardinal) then
                PCardinal(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Word) then
                PWord(Bind.valuep)^ := Value
              else
                PByte(Bind.valuep)^ := Value;
    SQLT_BFLOAT,
    SQLT_BDOUBLE,
    SQLT_DAT,
    SQLT_TIMESTAMP: InternalBindDouble(Index, SQLtype, Value);
    SQLT_LVC: begin
                IntToRaw(Value, PAnsiChar(@POCIVary(Bind.valuep).data[0]), @P);
                POCIVary(Bind.valuep).Len := P-@POCIVary(Bind.valuep).data[0];
              end
  end;
  Bind.indp[0] := 0;
end;
{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}

{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R-}{$IFEND}
procedure TZOraclePreparedStatement_A.BindUInteger(Index: Integer;
  SQLType: TZSQLType; Value: NativeUInt);
var
  Bind: PZOCIParamBind;
  P: PAnsiChar;
  Status: sword;
begin
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IF defined (RangeCheckEnabled) and not defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) and
     (SQLType <> BindList[Index].SQLType) then //keep registered types alive
    SQLType := BindList[Index].SQLType;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  if Bind.dty = SQLT_VNU then begin
    Status := FPlainDriver.OCINumberFromInt(FOCIError, @Value, SizeOf(NativeUInt), OCI_NUMBER_UNSIGNED, POCINumber(Bind.valuep));
    if Status <> OCI_SUCCESS then
      CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCINumberFromInt', ConSettings);
  end else if Bind.dty = SQLT_INT then
    if Bind.value_sz = SizeOf(Int64) then
      PInt64(Bind.valuep)^ := Value
    else if Bind.value_sz = SizeOf(Integer) then
      PInteger(Bind.valuep)^ := Value
    else if Bind.value_sz = SizeOf(SmallInt) then
      PSmallInt(Bind.valuep)^ := Value
    else
      PShortInt(Bind.valuep)^ := Value
  else if Bind.dty = SQLT_UIN then
    if Bind.value_sz = SizeOf(UInt64) then
      PUInt64(Bind.valuep)^ := Value
    else if Bind.value_sz = SizeOf(Cardinal) then
      PCardinal(Bind.valuep)^ := Value
    else if Bind.value_sz = SizeOf(Word) then
      PWord(Bind.valuep)^ := Value
    else
      PByte(Bind.valuep)^ := Value
  else begin
    IntToRaw(Value, PAnsiChar(@POCIVary(Bind.valuep).data[0]), @P);
    POCIVary(Bind.valuep).Len := P-@POCIVary(Bind.valuep).data[0];
  end;
  Bind.indp[0] := 0;
end;
{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}

procedure TZOraclePreparedStatement_A.InternalBindDouble(Index: Integer;
  SQLType: TZSQLType; const Value: Double);
var
  Bind: PZOCIParamBind;
  status: sword;
  TS: TZTimeStamp;
  procedure SetRaw;
  begin
    case SQLType of
      stBoolean:    fRawTemp := BoolStrIntsRaw[Value <> 0];
      stSmall,
      stInteger,
      stLong:       fRawTemp := IntToRaw(Trunc(Value));
      stDate:       fRawTemp := DateTimeToRawSQLDate(Value, ConSettings^.WriteFormatSettings, False);
      stTime:       fRawTemp := DateTimeToRawSQLTime(Value, ConSettings^.WriteFormatSettings, False);
      stTimeStamp:  fRawTemp := DateTimeToRawSQLTimeStamp(Value, ConSettings^.WriteFormatSettings, False);
      else          fRawTemp := FloatToSqlRaw(Value);
    end;
    SetRawByteString(Index{$IFNDEF GENERIC_INDEX}+1{$ENDIF}, fRawTemp)
  end;
begin
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) and
     (SQLType <> BindList[Index].SQLType) then
    SQLType := BindList[Index].SQLType;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  case Bind.dty of
    SQLT_VNU:   begin
                  status := FPlainDriver.OCINumberFromReal(FOracleConnection.GetErrorHandle, @Value, SizeOf(Double), POCINumber(Bind.valuep));
                  if Status <> OCI_SUCCESS then
                    CheckOracleError(FPLainDriver, FOCIError, Status, lcOther, '', ConSettings);
                end;
    SQLT_BFLOAT:  PSingle(Bind.valuep)^ := Value;
    SQLT_BDOUBLE: PDouble(Bind.valuep)^ := Value;
    SQLT_DAT:   begin
                  DecodeDate(Value, TS.Year, TS.Month, TS.Day); //oracle does not accept 0 dates
                  POraDate(Bind^.valuep).Cent   := TS.Year div 100 +100;
                  POraDate(Bind^.valuep).Year   := TS.Year mod 100 +100;
                  POraDate(Bind^.valuep).Month  := TS.Month;
                  PInteger(@POraDate(Bind^.valuep).Day)^ := 0; //init all remaining fields to 0 with one 4Byte value
                  POraDate(Bind^.valuep).Day    := TS.Day;
                end;
    SQLT_TIMESTAMP: begin
                  DecodeDate(Value, TS.Year, TS.Month, TS.Day); //oracle does not accept 0 dates
                  DecodeTime(Value, TS.Hour, TS.Minute, TS.Second, PWord(@TS.Fractions)^);
                  TS.Fractions := Word(TS.Fractions) * 1000000;
                  Status := FPlainDriver.OCIDateTimeConstruct(FOracleConnection.GetConnectionHandle,
                    FOCIError, PPOCIDescriptor(Bind.valuep)^, TS.Year, TS.Month, TS.Day,
                      TS.Hour, TS.Minute, TS.Second, TS.Fractions, nil, 0);
                  if Status <> OCI_SUCCESS then
                    CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, '', ConSettings);
                end;
    SQLT_INT,
    SQLT_UIN:   {$IFDEF CPU64}
                BindSInteger(Index, SQLType, Trunc(Value));
                {$ELSE}
                SetLong(Index{$IFNDEF GENERIC_INDEX}+1{$ENDIF}, Trunc(Value));
                {$ENDIF}
    else SetRaw;
  end;
  Bind.indp[0] := 0;
end;

procedure TZOraclePreparedStatement_A.SetBigDecimal(Index: Integer;
  const Value: TBCD);
var
  Bind: PZOCIParamBind;
  status: sword;
  TS: TZTimeStamp;
  SQLType: TZSQLType;
  procedure SetRaw;
  begin
    SetRawByteString(Index{$IFNDEF GENERIC_INDEX}+1{$ENDIF}, {$IFDEF UNICODE}UnicodeStringToAscii7{$ENDIF}(BCDToStr(Value)))
  end;
begin
  {$IFNDEF GENERIC_INDEX}Index := Index-1;{$ENDIF}
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) and
     (stBigDecimal <> BindList[Index].SQLType)
  then SQLType := BindList[Index].SQLType
  else SQLType := stBigDecimal;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  case Bind.dty of
    SQLT_VNU:     begin
                    Bind.indp[0] := BCD2Nvu(Value, POCINUmber(Bind.valuep));
                    Exit;
                  end;
    SQLT_BFLOAT:  PSingle(Bind.valuep)^ := BCDToDouble(Value);
    SQLT_BDOUBLE: PDouble(Bind.valuep)^ := BCDToDouble(Value);
    SQLT_DAT:   begin
                  DecodeDate(BCDToDouble(Value), TS.Year, TS.Month, TS.Day); //oracle does not accept 0 dates
                  POraDate(Bind^.valuep).Cent   := TS.Year div 100 +100;
                  POraDate(Bind^.valuep).Year   := TS.Year mod 100 +100;
                  POraDate(Bind^.valuep).Month  := TS.Month;
                  PInteger(@POraDate(Bind^.valuep).Day)^ := 0; //init all remaining fields to 0 with one 4Byte value
                  POraDate(Bind^.valuep).Day    := TS.Day;
                end;
    SQLT_TIMESTAMP: begin
                  PDouble(@fABuffer[0])^ := BCDToDouble(Value);
                  DecodeDate(PDouble(@fABuffer[0])^, TS.Year, TS.Month, TS.Day); //oracle does not accept 0 dates
                  DecodeTime(PDouble(@fABuffer[0])^, TS.Hour, TS.Minute, TS.Second, PWord(@TS.Fractions)^);
                  TS.Fractions := Word(TS.Fractions) * 1000000;
                  Status := FPlainDriver.OCIDateTimeConstruct(FOracleConnection.GetConnectionHandle,
                    FOCIError, PPOCIDescriptor(Bind.valuep)^, TS.Year, TS.Month, TS.Day,
                      TS.Hour, TS.Minute, TS.Second, TS.Fractions, nil, 0);
                  if Status <> OCI_SUCCESS then
                    CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, '', ConSettings);
                end;

    SQLT_INT:   {$IFDEF CPU64}
                BindSInteger(Index, stLong, BCD2Int64(Value));
                {$ELSE}
                SetLong(Index{$IFNDEF GENERIC_INDEX}+1{$ENDIF}, BCD2Int64(Value));
                {$ENDIF}
    SQLT_UIN:   {$IFDEF CPU64}
                BindSInteger(Index, stULong, BCD2UInt64(Value));
                {$ELSE}
                SetLong(Index{$IFNDEF GENERIC_INDEX}+1{$ENDIF}, BCD2UInt64(Value));
                {$ENDIF}
    else        SetRaw;
  end;
  Bind.indp[0] := 0;
end;

{**
  Sets the designated parameter to a Java <code>boolean</code> value.
  The driver converts this
  to an SQL <code>BIT</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetBoolean(Index: Integer;
  Value: Boolean);
begin
  BindUInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stBoolean, Ord(Value));
end;

{**
  Sets the designated parameter to a Java <code>unsigned 8Bit int</code> value.
  The driver converts this
  to an SQL <code>BYTE</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetByte(Index: Integer; Value: Byte);
begin
  BindUInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stByte, Cardinal(Value));
end;

{**
  Sets the designated parameter to a Java <code>currency</code> value.
  The driver converts this
  to an SQL <code>CURRENCY</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetCurrency(Index: Integer;
  const Value: Currency);
var
  Bind: PZOCIParamBind;
  SQLType: TZSQLType;
  P: PAnsiChar;
begin
  {$IFNDEF GENERIC_INDEX}
  Index := Index -1;
  {$ENDIF}
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType)
  then SQLType := BindList[Index].SQLType
  else SQLType := stCurrency;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  if Bind.dty = SQLT_VNU then
    Curr2vnu(Value, POCINumber(Bind.valuep))
  else if Bind.dty = SQLT_BDOUBLE then
    PDouble(Bind.valuep)^ := Value
  else begin
    CurrToRaw(Value, PAnsiChar(@POCIVary(Bind.valuep).data[0]), @P);
    POCIVary(Bind.valuep).Len := P-@POCIVary(Bind.valuep).data[0];
  end;
  Bind.indp[0] := 0;
end;

procedure TZOraclePreparedStatement_A.SetDataArray(ParameterIndex: Integer;
  const Value; const SQLType: TZSQLType; const VariantType: TZVariantType);
var
  Bind: PZOCIParamBind; //ora bind variable
  I, BufferSize: Integer;
  ArrayLen: Cardinal;
  ClientCP: Word;
  P: PAnsiChar;
  TS: TZTimeStamp;
  Status: sword;
  OraDate: POraDate;
label bind_direct;
  {$R-}
  procedure SetLobs;
  var I: Integer;
    Lob: IZBLob;
    WriteTempBlob: IZOracleBlob;
    OraLobs: TInterfaceDynArray;
    Arr: TZArray;
  label write_lob;
  begin
    SetLength(OraLobs, ArrayLen);
    Arr := PZArray(BindList[ParameterIndex].Value)^;
    Arr.VArray := Pointer(OraLobs);
    BindList.Put(ParameterIndex, Arr, True);
    if SQLType = stBinaryStream then begin
      if (Bind.dty <> SQLT_BLOB) or (Bind.value_sz <> SizeOf(POCIDescriptor)) or (Bind.curelen <> ArrayLen) then
        InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, SizeOf(POCIDescriptor));
      for i := 0 to ArrayLen -1 do
        if (TInterfaceDynArray(Value)[I] <> nil) and Supports(TInterfaceDynArray(Value)[I], IZBlob, Lob) and not Lob.IsEmpty then begin
          WriteTempBlob := TZOracleBlob.Create(FPlainDriver,
            nil, 0, FOracleConnection.GetServiceContextHandle, FOracleConnection.GetErrorHandle,
            PPOCIDescriptor(Bind^.valuep+I*SizeOf(POCIDescriptor))^, ChunkSize, ConSettings);
write_lob:WriteTempBlob.CreateBlob;
          WriteTempBlob.WriteLobFromBuffer(Lob.GetBuffer, Lob.Length);
          OraLobs[i] := WriteTempBlob; //destroy old interface or replace it
          Lob := nil;
          WriteTempBlob := nil;
        {$R-}
          Bind.indp[i] := 0;
        end else
          Bind.indp[i] := -1;
        {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
    end else begin
      if (Bind.dty <> SQLT_CLOB) or (Bind.value_sz <> SizeOf(POCIDescriptor)) or (Bind.curelen <> ArrayLen) then
        InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, SizeOf(POCIDescriptor));
      for i := 0 to ArrayLen -1 do
        if (TInterfaceDynArray(Value)[I] <> nil) and Supports(TInterfaceDynArray(Value)[I], IZBlob, Lob) and not Lob.IsEmpty then begin
          if Lob.IsClob then
            Lob.GetPAnsiChar(ClientCP)
          else begin
            FRawTemp := GetValidatedAnsiStringFromBuffer(Lob.GetBuffer, lob.Length, Connection.GetConSettings);
            Lob := TZOracleClob.Create(FPlainDriver,
              nil, 0, FOracleConnection.GetConnectionHandle,
              FOracleConnection.GetServiceContextHandle, FOracleConnection.GetErrorHandle,
              PPOCIDescriptor(Bind^.valuep+I*SizeOf(POCIDescriptor))^,
              ChunkSize, ConSettings, ConSettings^.ClientCodePage^.CP);
            Lob.SetPAnsiChar(Pointer(FRawTemp), ClientCP, Length(FRawTemp));
            FRawTemp := '';
          end;
          if not Supports(Lob, IZOracleBlob, WriteTempBlob) or not (WriteTempBlob.IsCLob) then
            WriteTempBlob := TZOracleClob.Create(FPlainDriver,
              nil, 0, FOracleConnection.GetConnectionHandle,
              FOracleConnection.GetServiceContextHandle, FOracleConnection.GetErrorHandle,
              PPOCIDescriptor(Bind^.valuep+I*SizeOf(POCIDescriptor))^,
              ChunkSize, ConSettings, ConSettings^.ClientCodePage^.CP);
          goto write_lob;
        end else
          Bind.indp[i] := -1;
    end;
  end;
  procedure BindRawStrings(const ClientStrings: TRawByteStringDynArray);
  var BufferSize, I: Integer;
  begin
    BufferSize := 0;
    for i := 0 to ArrayLen -1 do
      if Pointer(ClientStrings[i]) <> nil then
        {$IFDEF WITH_TBYTES_AS_RAWBYTESTRING}
        BufferSize := Max(BufferSize, Length(ClientStrings[I]) -1);
        {$ELSE}
        BufferSize := Max(BufferSize, PLengthInt(NativeUInt(ClientStrings[I]) - StringLenOffSet)^);
        {$ENDIF}
    if (Bind.dty <> SQLT_LVC) or (Bind.value_sz < BufferSize+SizeOf(Integer)) or (Bind.curelen <> ArrayLen) then
      InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, BufferSize);
    P := Bind.valuep;
    for i := 0 to ArrayLen -1 do begin
      if (Pointer(ClientStrings[I]) = nil) then
        POCILong(P).Len := 0
      else begin
        {$IFDEF WITH_TBYTES_AS_RAWBYTESTRING}
        POCILong(P).Len := Length(ClientStrings[I]) -1;
        {$ELSE}
        POCILong(P).Len := PLengthInt(NativeUInt(ClientStrings[I]) - StringLenOffSet)^;
        {$ENDIF}
        Move(Pointer(ClientStrings[i])^,POCILong(P).data[0], POCILong(P).Len);
      end;
      Inc(P, Bind.value_sz);
    end;
  end;
  procedure BindRawFromUnicodeStrings;
  var BufferSize, I: Integer;
  begin
    BufferSize := 0;
    for i := 0 to ArrayLen -1 do
      BufferSize := Max(BufferSize, Length(TUnicodeStringDynArray(Value)[I]));
    BufferSize := (BufferSize shl 2);
    if (Bind.dty <> SQLT_LVC) or (Bind.value_sz < BufferSize+SizeOf(Integer)) or (Bind.curelen <> ArrayLen) then
      InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, BufferSize);
    P := Bind.valuep;
    for i := 0 to ArrayLen -1 do begin
      POCILong(P).Len := ZEncoding.PUnicode2PRawBuf(Pointer(TUnicodeStringDynArray(Value)[I]),
        @POCILong(P).data[0], Length(TUnicodeStringDynArray(Value)[I]), BufferSize, ClientCP);
      Inc(P, Bind.value_sz);
    end;
  end;
  procedure BindRawFromCharRec;
  var BufferSize, I: Integer;
  begin
    BufferSize := 0;
    for i := 0 to ArrayLen -1 do
      BufferSize := Max(BufferSize, TZCharRecDynArray(Value)[I].Len);
    if TZCharRecDynArray(Value)[0].CP <> ClientCP then
      BufferSize := BufferSize shl 2; //oversized for best fit
    if (Bind.dty <> SQLT_LVC) or (Bind.value_sz < BufferSize+SizeOf(Integer)) or (Bind.curelen <> ArrayLen) then
      InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, BufferSize);
    P := Bind.valuep;
    for i := 0 to ArrayLen -1 do begin
      if TZCharRecDynArray(Value)[I].CP = ClientCP then begin
        POCILong(P).Len := TZCharRecDynArray(Value)[I].Len;
        Move(TZCharRecDynArray(Value)[I].P^,POCILong(P).data[0], POCILong(P).Len);
      end else if TZCharRecDynArray(Value)[I].CP = zCP_UTF16
        then POCILong(P).Len := ZEncoding.PUnicode2PRawBuf(TZCharRecDynArray(Value)[I].P,
          @POCILong(P).data[0], TZCharRecDynArray(Value)[I].Len, BufferSize, ClientCP)
        else POCILong(P).Len := ZEncoding.PRawToPRawBuf(TZCharRecDynArray(Value)[I].P,
          @POCILong(P).data[0], TZCharRecDynArray(Value)[I].Len, BufferSize, TZCharRecDynArray(Value)[I].CP, ClientCP);
      Inc(P, Bind.value_sz);
    end;
  end;

  procedure BindFromAutoEncode;
  var ClientStrings: TRawByteStringDynArray;
    var I: Integer;
  begin
    SetLength(ClientStrings, ArrayLen);
      for i := 0 to ArrayLen -1 do
         if (Pointer(TStringDynArray(Value)[I]) <> nil) then
    BindRawStrings(ClientStrings);
  end;
  procedure BindConvertedRaw2RawStrings(CP: Word);
  var BufferSize, I: Integer;
  begin
    BufferSize := 0;
    for i := 0 to ArrayLen -1 do
      if Pointer(TRawByteStringDynArray(Value)[i]) <> nil then
        {$IFDEF WITH_TBYTES_AS_RAWBYTESTRING}
        BufferSize := Max(BufferSize, Length(TRawByteStringDynArray(Value)[I]) -1);
        {$ELSE}
        BufferSize := Max(BufferSize, PLengthInt(NativeUInt(TRawByteStringDynArray(Value)[I]) - StringLenOffSet)^);
        {$ENDIF}
    BufferSize := BufferSize shl 2; //oversized
    if (Bind.dty <> SQLT_LVC) or (Bind.value_sz < BufferSize+SizeOf(Integer)) or (Bind.curelen <> ArrayLen) then
      InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, BufferSize);
    P := Bind.valuep;
    for i := 0 to ArrayLen -1 do begin
      POCILong(P).Len := ZEncoding.PRawToPRawBuf(Pointer(TRawByteStringDynArray(Value)[I]),
        @POCILong(P).data[0], Length(TRawByteStringDynArray(Value)[I]), BufferSize, CP, ClientCP);
      Inc(P, Bind.value_sz);
    end;
  end;
begin
  inherited SetDataArray(ParameterIndex, Value, SQLType, VariantType);
  {$IFNDEF GENERIC_INDEX}
  ParameterIndex := ParameterIndex - 1;
  {$ENDIF}
  Bind := @FOraVariables[ParameterIndex];
  ClientCP := ConSettings^.ClientCodePage.CP;
  ArrayLen := {%H-}PArrayLenInt({%H-}NativeUInt(Value) - ArrayLenOffSet)^{$IFDEF FPC}+1{$ENDIF}; //FPC returns High() for this pointer location
  case SQLType of
    stBoolean, stByte, stShort, stWord, stSmall, stLongWord, stInteger, stFloat, stDouble: begin
bind_direct:
        InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen);
        if BatchDMLArrayCount > 1 then begin
          Status := FPlainDriver.OCIBindByPos(FOCIStmt, Bind.bindpp, FOCIError, ParameterIndex + 1,
            Pointer(Value), Bind.value_sz, Bind.dty, Bind.indp, nil, nil, 0, nil, OCI_DEFAULT);
          if Status <> OCI_SUCCESS then
            CheckOracleError(FPlainDriver, FOCIError, Status, lcExecute, ASQL, ConSettings);
        end else case Bind.value_sz of
          8: PDouble(Bind^.valuep)^ := TDoubleDynArray(Value)[0];
          4: PCardinal(Bind^.valuep)^ := TCardinalDynArray(Value)[0];
          2: PWord(Bind^.valuep)^ := TWordDynArray(Value)[0];
          else PByte(Bind^.valuep)^ := TByteDynArray(Value)[0];
        end;
      end;
    stLong, stULong: //old oracle does not support 8 byte ordinals
        if FCanBindInt64 and (VariantType <> vtRawByteString) then
          goto bind_direct
        else begin
          if (Bind.dty <> SQLT_VNU) or (Bind.value_sz <> SizeOf(TOciNumber)) or (Bind.curelen <> ArrayLen) then
            InitBuffer(stBigDecimal, Bind, ParameterIndex, ArrayLen, 20);
          P := Bind.valuep;
          if (VariantType <> vtRawByteString) then begin
            if SQLType = stLong then
              for i := 0 to ArrayLen -1 do begin
                FPlainDriver.OCINumberFromInt(FOCIError, @TInt64DynArray(Value)[i],
                  SizeOf(Int64), OCI_NUMBER_SIGNED, POCINumber(P));
                Inc(P, Bind.value_sz);
              end
            else
              for i := 0 to ArrayLen -1 do begin
                FPlainDriver.OCINumberFromInt(FOCIError, @TUInt64DynArray(Value)[i],
                  SizeOf(Int64), OCI_NUMBER_UNSIGNED, POCINumber(P));
                Inc(P, Bind.value_sz);
              end;
          end else begin

          end;
        end;
    stCurrency: begin
        if (Bind.dty <> SQLT_VNU) or (Bind.value_sz <> SizeOf(TOCINumber)) or (Bind.curelen <> ArrayLen) then
          InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, SizeOf(TOCINumber));
        for i := 0 to ArrayLen -1 do
          Curr2vnu(TCurrencyDynArray(Value)[i], POCINumber(Bind.valuep+I*SizeOf(TOCINumber)));
      end;
    stBigDecimal: begin
        if (Bind.dty <> SQLT_VNU) or (Bind.value_sz <> SizeOf(TOCINumber)) or (Bind.curelen <> ArrayLen) then
          //note as long we do not have a Value2OraNumber conversion we'll use the ora double instead!!
          InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, SizeOf(TOCINumber));
        for i := 0 to ArrayLen -1 do
          {$R-}
          Bind.indp[I] := BCD2Nvu(TBCDDynArray(Value)[i], POCINumber(Bind.valuep+I*SizeOf(TOCINumber)));
          {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
        Exit;
      end;
    stDate: begin
        if (Bind.dty <> SQLT_DAT) or (Bind.value_sz <> SizeOf(TOraDate)) or (Bind.curelen <> ArrayLen) then
          InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, SizeOf(TOraDate));
        FillChar(Bind^.valuep^, ArrayLen*SizeOf(TOraDate), #0);
        for i := 0 to ArrayLen -1 do begin
          DecodeDate(TDateTimeDynArray(Value)[i], TS.Year, TS.Month, TS.Day);
          OraDate := POraDate(Bind^.valuep+I*SizeOf(TOraDate));
          OraDate.Cent  := Ts.Year div 100 + 100;
          OraDate.Year  := Ts.Year mod 100 + 100;
          OraDate.Month := TS.Month;
          OraDate.Day   := TS.Day;
        end;
      end;
    stTime, stTimeStamp: begin //msec precision -> need a descriptor
        if (Bind.dty <> SQLT_TIMESTAMP) or (Bind.value_sz <> SizeOf(POCIDescriptor)) or (Bind.curelen <> ArrayLen) then
          InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, SizeOf(SizeOf(POCIDescriptor)));
        for i := 0 to ArrayLen -1 do begin
          DecodeDate(TDateTimeDynArray(Value)[i], TS.Year, TS.Month, TS.Day); //oracle doesn't accept 0 dates
          DecodeTime(TDateTimeDynArray(Value)[i], TS.Hour, TS.Minute, TS.Second, PWord(@TS.Fractions)^);
          TS.Fractions := PWord(@TS.Fractions)^ * 1000000;
          Status := FPlainDriver.OCIDateTimeConstruct(FOracleConnection.GetConnectionHandle,
              FOCIError, PPOCIDescriptor(Bind^.valuep+I*SizeOf(POCIDescriptor))^, //direct addressing descriptor to array. So we don't need to free the mem again
              TS.Year, TS.Month, TS.Day, TS.Hour, TS.Minute, TS.Second, TS.Fractions, nil, 0);
          if Status <> OCI_SUCCESS then
            CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCIDateTimeConstruct', ConSettings);
        end;
      end;
    stGUID: begin
        if (Bind.dty <> SQLT_AFC) or (Bind.value_sz <> StrGUIDLen) or (Bind.curelen <> ArrayLen) then
          InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen);
        for i := 0 to ArrayLen -1 do
          GUIDToBuffer(@TGUIDDynArray(Value)[I], (Bind.valuep+I*StrGUIDLen), []);
      end;
    stBytes: begin
        BufferSize := 0;
        for i := 0 to ArrayLen -1 do
          BufferSize := Max(BufferSize, Length(TBytesDynArray(Value)[I]));
        if (Bind.dty <> SQLT_LVB) or (Bind.value_sz < BufferSize+SizeOf(Integer)) or (Bind.curelen <> ArrayLen) then
          InitBuffer(SQLType, Bind, ParameterIndex, ArrayLen, BufferSize);
        for i := 0 to ArrayLen -1 do begin
          BufferSize := Length(TBytesDynArray(Value)[I]);
          PInteger(Bind.valuep+I*Bind.value_sz)^ := BufferSize;
          if BufferSize > 0 then
            Move(Pointer(TBytesDynArray(Value)[I])^,(Bind.valuep+I*Bind.value_sz+SizeOf(Integer))^, BufferSize);
        end;
    end;
    stString, stUnicodeString:
      case VariantType of
        {$IFNDEF UNICODE}
        vtString:
          if not ConSettings.AutoEncode
          then BindRawStrings(TRawByteStringDynArray(Value))
          else BindFromAutoEncode;
        {$ENDIF}
        {$IFNDEF NO_ANSISTRING}
        vtAnsiString:  if ZCompatibleCodePages(ClientCP, ZOSCodePage)
            then BindRawStrings(TRawByteStringDynArray(Value))
            else BindConvertedRaw2RawStrings(ZOSCodePage);
        {$ENDIF}
        {$IFNDEF NO_UTF8STRING}
        vtUTF8String: if ZCompatibleCodePages(ClientCP, zCP_UTF8)
            then BindRawStrings(TRawByteStringDynArray(Value))
            else BindConvertedRaw2RawStrings(zCP_UTF8);
        {$ENDIF}
        vtRawByteString: BindRawStrings(TRawByteStringDynArray(Value));
        vtCharRec: BindRawFromCharRec;
        {$IFDEF UNICODE}vtString,{$ENDIF}
        vtUnicodeString: BindRawFromUnicodeStrings;
        else raise Exception.Create('Unsupported String Variant');
      end;
    stAsciiStream, stUnicodeStream, stBinaryStream: begin
        SetLobs;
        Exit;
      end;
  end;
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  FillChar(Bind.indp^, SizeOf(SB2)*ArrayLen, #0);
end;

procedure TZOraclePreparedStatement_A.SetDate(Index: Integer;
  const Value: TDateTime);
begin
  InternalBindDouble(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stDate, Value);
end;

{**
  Sets the designated parameter to a Java <code>double</code> value.
  The driver converts this
  to an SQL <code>DOUBLE</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetDouble(Index: Integer;
  const Value: Double);
begin
  InternalBindDouble(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stDouble, Value);
end;

{**
  Sets the designated parameter to a Java <code>float</code> value.
  The driver converts this
  to an SQL <code>FLOAT</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetFloat(Index: Integer; Value: Single);
begin
  InternalBindDouble(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stFloat, Value);
end;

{**
  Sets the designated parameter to a Java <code>int</code> value.
  The driver converts this
  to an SQL <code>INTEGER</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetInt(Index, Value: Integer);
begin
  BindSInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stInteger, Value);
end;

{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R-}{$IFEND}
procedure TZOraclePreparedStatement_A.SetLong(Index: Integer;
  const Value: Int64);
{$IFDEF CPU64}
begin
  BindSInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stLong, Value);
{$ELSE}
var
  Bind: PZOCIParamBind;
  P: PAnsiChar;
  Status: sword;
  SQLType: TZSQLType;
begin
  {$IFNDEF GENERIC_INDEX}Index := Index-1;{$ENDIF}
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IF defined (RangeCheckEnabled) and not defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) and
     (stLong <> BindList[Index].SQLType) //keep registered types alive
  then SQLType := BindList[Index].SQLType
  else SQLType := stLong;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  case Bind.dty of
    SQLT_VNU: begin
        Status := FPlainDriver.OCINumberFromInt(FOCIError, @Value, SizeOf({$IFNDEF CPU64}Integer{$ELSE}Int64{$ENDIF}), OCI_NUMBER_SIGNED, POCINumber(Bind.valuep));
        if Status <> OCI_SUCCESS then
          CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCINumberFromInt', ConSettings);
      end;
    SQLT_INT: if Bind.value_sz = SizeOf(Int64) then
                PInt64(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Integer) then
                PInteger(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(SmallInt) then
                PSmallInt(Bind.valuep)^ := Value
              else
                PShortInt(Bind.valuep)^ := Value;
    SQLT_UIN: if Bind.value_sz = SizeOf(UInt64) then
                PUInt64(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Cardinal) then
                PCardinal(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Word) then
                PWord(Bind.valuep)^ := Value
              else
                PByte(Bind.valuep)^ := Value;
    SQLT_BFLOAT,
    SQLT_BDOUBLE,
    SQLT_DAT,
    SQLT_TIMESTAMP: InternalBindDouble(Index, SQLtype, Value);
    SQLT_LVC: begin
                IntToRaw(Value, PAnsiChar(@POCIVary(Bind.valuep).data[0]), @P);
                POCIVary(Bind.valuep).Len := P-@POCIVary(Bind.valuep).data[0];
              end
  end;
  Bind.indp[0] := 0;
{$ENDIF}
end;
{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}

{**
  Sets the designated parameter to SQL <code>NULL</code>.
  <P><B>Note:</B> You must specify the parameter's SQL type.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param sqlType the SQL type code defined in <code>java.sql.Types</code>
}
procedure TZOraclePreparedStatement_A.SetNull(Index: Integer;
  SQLType: TZSQLType);
var
  Bind: PZOCIParamBind;
begin
  {$IFNDEF GENERIC_INDEX}Index := Index -1;{$ENDIF}
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) then
    SQLType := BindList[Index].SQLType;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  Bind.indp[0] := -1;
end;

procedure TZOraclePreparedStatement_A.SetNullArray(ParameterIndex: Integer;
  const SQLType: TZSQLType; const Value; const VariantType: TZVariantType);
var I: Cardinal;
  Bind: PZOCIParamBind;
  P: PZArray;
begin
  inherited SetNullArray(ParameterIndex, SQLType, Value, VariantType);
  {$IFNDEF GENERIC_INDEX}
  ParameterIndex := ParameterIndex - 1;
  {$ENDIF}
  {$R-}
  Bind := @FOraVariables[ParameterIndex];
  P := BindList[ParameterIndex].Value;
  for i := 0 to {%H-}PArrayLenInt({%H-}NativeUInt(Value) - ArrayLenOffSet)^{$IFNDEF FPC}-1{$ENDIF} do
    Bind.indp[I] := -Ord(ZDbcUtils.IsNullFromArray(P, i));
  {$IFDEF RangeCheckEnabled}{$R+}{$ENDIF}
end;

{**
  Sets the designated parameter to a Java <code>ShortInt</code> value.
  The driver converts this
  to an SQL <code>ShortInt</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetShort(Index: Integer; Value: ShortInt);
begin
  BindSInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stShort, Value);
end;

{**
  Sets the designated parameter to a Java <code>SmallInt</code> value.
  The driver converts this
  to an SQL <code>SMALLINT</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetSmall(Index: Integer; Value: SmallInt);
begin
  BindSInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stSmall, Value);
end;

{**
  Sets the designated parameter to a <code>java.sql.Time</code> value.
  The driver converts this to an SQL <code>TIME</code> value
  when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetTime(Index: Integer;
  const Value: TDateTime);
begin
  InternalBindDouble(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stTime, Value);
end;

{**
  Sets the designated parameter to a <code>java.sql.Timestamp</code> value.
  The driver converts this to an SQL <code>TIMESTAMP</code> value
  when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetTimestamp(Index: Integer;
  const Value: TDateTime);
begin
  InternalBindDouble(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stTimeStamp, Value);
end;

{**
  Sets the designated parameter to a Java <code>usigned 32bit int</code> value.
  The driver converts this
  to an SQL <code>INTEGER</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetUInt(Index: Integer; Value: Cardinal);
begin
  BindSInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stLongWord, Value);
end;

{**
  Sets the designated parameter to a Java <code>unsigned long long</code> value.
  The driver converts this
  to an SQL <code>BIGINT</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R-}{$IFEND}
procedure TZOraclePreparedStatement_A.SetULong(Index: Integer;
  const Value: UInt64);
{$IFDEF CPU64}
begin
  BindUInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stULong, Value);
{$ELSE}
var
  Bind: PZOCIParamBind;
  P: PAnsiChar;
  Status: sword;
  SQLType: TZSQLType;
begin
  CheckParameterIndex(Index);
  {$R-}
  Bind := @FOraVariables[Index];
  {$IF defined (RangeCheckEnabled) and not defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}
  if Boolean(BindList[Index].ParamType) and Boolean(BindList[Index].SQLType) and
     (stULong <> BindList[Index].SQLType) //keep registered types alive
  then SQLType := BindList[Index].SQLType
  else SQLType := stULong;
  if (BindList[Index].SQLType <> SQLType) or (Bind.valuep = nil) or (Bind.curelen <> 1) then
    InitBuffer(SQLType, Bind, Index, 1);
  case Bind.dty of
    SQLT_VNU: begin
        Status := FPlainDriver.OCINumberFromInt(FOCIError, @Value, SizeOf({$IFNDEF CPU64}Integer{$ELSE}Int64{$ENDIF}), OCI_NUMBER_SIGNED, POCINumber(Bind.valuep));
        if Status <> OCI_SUCCESS then
          CheckOracleError(FPlainDriver, FOCIError, Status, lcOther, 'OCINumberFromInt', ConSettings);
      end;
    SQLT_INT: if Bind.value_sz = SizeOf(Int64) then
                PInt64(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Integer) then
                PInteger(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(SmallInt) then
                PSmallInt(Bind.valuep)^ := Value
              else
                PShortInt(Bind.valuep)^ := Value;
    SQLT_UIN: if Bind.value_sz = SizeOf(UInt64) then
                PUInt64(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Cardinal) then
                PCardinal(Bind.valuep)^ := Value
              else if Bind.value_sz = SizeOf(Word) then
                PWord(Bind.valuep)^ := Value
              else
                PByte(Bind.valuep)^ := Value;
    SQLT_BFLOAT,
    SQLT_BDOUBLE,
    SQLT_DAT,
    SQLT_TIMESTAMP: InternalBindDouble(Index, SQLtype, Value);
    SQLT_LVC: begin
                IntToRaw(Value, PAnsiChar(@POCIVary(Bind.valuep).data[0]), @P);
                POCIVary(Bind.valuep).Len := P-@POCIVary(Bind.valuep).data[0];
              end
  end;
  Bind.indp[0] := 0;
{$ENDIF}
end;
{$IF defined (RangeCheckEnabled) and defined(WITH_UINT64_C1118_ERROR)}{$R+}{$IFEND}

{**
  Sets the designated parameter to a Java <code>unsigned 16bit int</code> value.
  The driver converts this
  to an SQL <code>WORD</code> value when it sends it to the database.

  @param parameterIndex the first parameter is 1, the second is 2, ...
  @param x the parameter value
}
procedure TZOraclePreparedStatement_A.SetWord(Index: Integer; Value: Word);
begin
  BindUInteger(Index{$IFNDEF GENERIC_INDEX}-1{$ENDIF}, stWord, Value);
end;

initialization

{ RealPrepared stmts:
  http://www.postgresql.org/docs/9.1/static/sql-prepare.html }
SetLength(OraPreparableTokens, OCI_STMT_DECLARE);
OraPreparableTokens[OCI_STMT_SELECT-1].MatchingGroup  := 'SELECT';
OraPreparableTokens[OCI_STMT_UPDATE-1].MatchingGroup  := 'UPDATE';
OraPreparableTokens[OCI_STMT_DELETE-1].MatchingGroup  := 'DELETE';
OraPreparableTokens[OCI_STMT_INSERT-1].MatchingGroup  := 'INSERT';
OraPreparableTokens[OCI_STMT_CREATE-1].MatchingGroup  := 'CREATE';
OraPreparableTokens[OCI_STMT_DROP-1].MatchingGroup    := 'DROP';
OraPreparableTokens[OCI_STMT_ALTER-1].MatchingGroup   := 'ALTER';
OraPreparableTokens[OCI_STMT_BEGIN-1].MatchingGroup   := 'BEGIN';
OraPreparableTokens[OCI_STMT_DECLARE-1].MatchingGroup := 'DECLARE';

end.
