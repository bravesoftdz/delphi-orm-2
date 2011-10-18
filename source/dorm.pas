unit dorm;

interface

uses
  dorm.Commons,
  ioutils,
  classes,
  superobject,
  Generics.Collections,
  TypInfo,
  Rtti,
  dorm.Collections,
  dorm.UOW;
// ,dorm.Core.IdentityMap;

type
  TdormParam = class
  public
    Value: TValue;
  end;

  TdormParameters = class(TObjectList<TdormParam>)

  end;

  TdormCriteria = class(TInterfacedObject)
  private
    FItems: TObjectList<TdormCriteriaItem>;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    function Add(const Attribute: string; CompareOperator: TdormCompareOperator;
      Value: TValue; LogicRelation: TdormLogicRelation = lrAnd): TdormCriteria;
    function AddOr(const Attribute: string;
      CompareOperator: TdormCompareOperator; Value: TValue): TdormCriteria;
    function AddAnd(const Attribute: string;
      CompareOperator: TdormCompareOperator; Value: TValue): TdormCriteria;
    function Count: Integer;
    function GetCriteria(const index: Integer): TdormCriteriaItem;
    class function NewCriteria(const Attribute: string;
      CompareOperator: TdormCompareOperator; Value: TValue): TdormCriteria;
  end;

  TdormSimpleSearchCriteria = class(TInterfacedObject, IdormSearchCriteria)
  protected
    FSQL: string;
    FItemClassInfo: PTypeInfo;
  public
    constructor Create(AItemClassInfo: PTypeInfo; ASQL: string); virtual;
    function GetSQL: string;
    function GetItemClassInfo: PTypeInfo;
  end;

  TdormSearch = class(TdormSimpleSearchCriteria)
  private
    FParameters: TdormParameters;
  public
    constructor Create(AItemClassInfo: PTypeInfo; ASQL: string);
    destructor Destroy; override;
    property Parameters: TdormParameters read FParameters;
  end;

  TSession = class(TdormInterfacedObject)
  private
    FCTX: TRttiContext;
    FDictTables: TDictionary<string, string>;
    FDictMapping: TDictionary<string, TArray<TdormFieldMapping>>;
    // FIdentityMap: TIdentityMap;
    FMapping: ISuperObject;
    FPersistStrategy: IdormPersistStrategy;
    FUOWInsert, FUOWUpdate, FUOWDelete: TObjectList<TObject>;
    // FPackageName: string;
    FLogger: IdormLogger;
    FEnvironment: TdormEnvironment;
    EnvironmentNames: TArray<string>;
    procedure DoOnAfterLoad(AObject: TObject);
    procedure DoOnBeforeDelete(AObject: TObject);
    procedure DoOnBeforeUpdate(AObject: TObject);
    procedure DoOnBeforeInsert(AObject: TObject);
  protected
    // Validations
    procedure DoUpdateValidation(AObject: TObject);
    procedure DoInsertValidation(AObject: TObject);
    procedure DoDeleteValidation(AObject: TObject);
    function CreateLogger: IdormLogger;
    function Qualified(const AClassName: string): string;
    function GetPackageName(const AClassName: string): string;
    function GetStrategy: IdormPersistStrategy;
    function GetFieldNameFromAttributeName(_table_mapping
      : TArray<TdormFieldMapping>; _child_class_name: string;
      _child_field_name: string): string;
    procedure InsertHasManyRelation(APKValue: TValue; ARttiType: TRttiType;
      AClassName: string; AObject: TObject);
    procedure InsertHasOneRelation(APKValue: TValue; ARttiType: TRttiType;
      AClassName: string; AObject: TObject);
    procedure DeleteHasManyRelation(APKValue: TValue; ARttiType: TRttiType;
      AClassName: string; AObject: TObject);
    function CreateChildLoaderSearch(AChildClassName, AChildTableName,
      AChildRelationField: string; AParentPKValue: TValue): IdormSearchCriteria;
    procedure LoadHasManyRelation(APKValue: TValue; ARttiType: TRttiType;
      AClassName: string; AObject: TObject);
    procedure LoadHasManyRelationByPropertyName(APKValue: TValue;
      ARttiType: TRttiType; AClassName: string; APropertyName: string;
      var AObject: TObject);
    procedure LoadHasOneRelation(APKValue: TValue; ARttiType: TRttiType;
      AClassName: string; AObject: TObject);
    procedure LoadBelongsToRelation(APKValue: TValue; ARttiType: TRttiType;
      AClassName: string; AObject: TObject);
    procedure LoadHasOneRelationByPropertyName(APKValue: TValue;
      ARttiType: TRttiType; AClassName: string; APropertyName: string;
      var AObject: TObject);
    procedure LoadBelongsToRelationByPropertyName(APKValue: TValue;
      ARttiType: TRttiType; AClassName, APropertyName: string;
      var AObject: TObject);
    function Load(ATypeInfo: PTypeInfo; const Value: TValue): TObject; overload;
  public
    constructor Create(Environment: TdormEnvironment); virtual;
    destructor Destroy; override;
    // Environments
    function GetEnv: string;
    // Core
    function Clone<T: class, constructor>(Obj: T): T;
    function GetTableName(AClassName: string): string;
    function GetTableMapping(AClassName: string): TArray<TdormFieldMapping>;
    function GetMapping: ISuperObject;
    function GetLogger: IdormLogger;
    procedure Configure(TextReader: TTextReader);
    function Save(AObject: TObject; SaveType: TdormSaveType = stAllGraph)
      : TValue; overload;
    procedure Update(AObject: TObject);
    procedure Save(dormUOW: TdormUOW); overload;
    procedure Delete(AObject: TObject);
    procedure InsertCollection(Collection: TdormCollection);
    procedure UpdateCollection(Collection: TdormCollection);
    procedure DeleteCollection(Collection: TdormCollection);
    procedure Extract(AOID: string);
    procedure LoadRelations(AObject: TObject); overload;
    procedure LoadRelations(AList: TdormCollection); overload;
    function Load<T: class>(const Value: TValue): T; overload;
    // function Load<T: class>(const Value: string; AObject: T): Boolean; overload;
    procedure LazyLoadFor(const APropertyName: string; AObject: TObject);
    procedure SetLazyLoadFor(ATypeInfo: PTypeInfo; const APropertyName: string;
      const Value: Boolean);
    function FindOne<T: class>(Criteria: TdormCriteria;
      FreeCriteria: Boolean = true): T; overload;
    function FindOne(AItemClassInfo: PTypeInfo; Criteria: TdormCriteria;
      FreeCriteria: Boolean = true): TObject; overload;
    function List(AItemClassInfo: PTypeInfo; Criteria: TdormCriteria;
      FreeCriteria: Boolean = false): TdormCollection; overload;
    function List(AdormSearchCriteria: IdormSearchCriteria)
      : TdormCollection; overload;
    function ListAll<T: class>(): TdormCollection;
    function List<T: class>(Criteria: TdormCriteria;
      FreeCriteria: Boolean = true): TdormCollection; overload;
    function Count(AClassType: TClass): Int64;
    procedure DeleteAll(AClassType: TClass);
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    function GetPersistentClassesName(WithPackage: Boolean = false)
      : TList<string>;
    function Strategy: IdormPersistStrategy;
    function OIDIsSet(Obj: TObject): Boolean;
    procedure ClearOID(Obj: TObject);
    class function CreateConfigured(TextReader: TTextReader;
      Environment: TdormEnvironment): TSession;
  end;

implementation

uses
  dorm.adapter.Firebird,
  SysUtils,
  dorm.Utils,
  dorm.InterposedObject;

{ TSession }

procedure TSession.ClearOID(Obj: TObject);
var
  rt: TRttiType;
  pk_value: TValue;
begin
  rt := FCTX.GetType(Obj.ClassType);
  TdormUtils.SetField(Obj, GetPKName(GetTableMapping(rt.ToString)),
    GetStrategy.GetNullKeyValue);
end;

function TSession.Clone<T>(Obj: T): T;
begin
  Result := T(TdormUtils.Clone(Obj));
end;

procedure TSession.Commit;
begin
  GetStrategy.Commit;
  GetLogger.ExitLevel('TSession.Commit');
end;

procedure TSession.Configure(TextReader: TTextReader);
var
  s: string;
begin
  try
    s := TextReader.ReadToEnd;
  finally
    TextReader.Free;
  end;
  try
    FMapping := TSuperObject.ParseString(pwidechar(s), true);
    if not assigned(FMapping) then
      raise Exception.Create('Cannot parse configuration');
    FLogger := CreateLogger;
    FPersistStrategy := GetStrategy;
    FPersistStrategy.ConfigureStrategy(FMapping.O['persistence'].O[GetEnv]);
    FPersistStrategy.InitStrategy;
  except
    on E: Exception do
    begin
      try
        GetLogger.Error(E.Message);
      except
      end;
      raise;
    end;
  end;
end;

function TSession.Count(AClassType: TClass): Int64;
var
  _table: string;
begin
  _table := GetTableName(AClassType.ClassName);
  Result := GetStrategy.Count(_table);
end;

constructor TSession.Create(Environment: TdormEnvironment);
begin
  inherited Create;
  FEnvironment := Environment;
  FDictTables := TDictionary<string, string>.Create(128);
  FDictMapping := TDictionary < string, TArray < TdormFieldMapping >>
    .Create(128);
  FUOWInsert := TObjectList<TObject>.Create(true);
  FUOWUpdate := TObjectList<TObject>.Create(true);
  FUOWDelete := TObjectList<TObject>.Create(true);
  SetLength(EnvironmentNames, 3);
  EnvironmentNames[ord(deDevelopment)] := 'development';
  EnvironmentNames[ord(deTest)] := 'test';
  EnvironmentNames[ord(deRelease)] := 'release';
end;

function TSession.CreateChildLoaderSearch(AChildClassName, AChildTableName,
  AChildRelationField: string; AParentPKValue: TValue): IdormSearchCriteria;
begin
  Result := GetStrategy.CreateChildLoaderSearch
    (FCTX.FindType(Qualified(AChildClassName)).AsInstance.Handle,
    AChildClassName, GetTableName(AChildClassName), AChildRelationField,
    AParentPKValue);
end;

class function TSession.CreateConfigured(TextReader: TTextReader;
  Environment: TdormEnvironment): TSession;
begin
  Result := TSession.Create(Environment);
  try
    Result.Configure(TextReader);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TSession.CreateLogger: IdormLogger;
var
  LogClassName: string;
  l: TRttiType;
begin
  LogClassName := FMapping.O['config'].s['logger_class_name'];
  if LogClassName = EmptyStr then
    Result := nil // consider null object pattern
  else
  begin
    l := FCTX.FindType(LogClassName);
    if Supports(l.AsInstance.MetaclassType, IdormLogger) then
      Supports(l.AsInstance.MetaclassType.Create, IdormLogger, Result);
  end;
end;

procedure TSession.Delete(AObject: TObject);
var
  RttiType: TRttiType;
  _table, _class_name: string;
  fields: TArray<TdormFieldMapping>;
  PKValue: TValue;
begin
  GetLogger.EnterLevel('Delete');
  DoDeleteValidation(AObject);
  DoOnBeforeDelete(AObject);
  RttiType := FCTX.GetType(AObject.ClassInfo);
  _class_name := RttiType.ToString;
  _table := GetTableName(_class_name);
  fields := GetTableMapping(_class_name);
  PKValue := GetPKValue(RttiType, GetTableMapping(AObject.ClassName), AObject);
  DeleteHasManyRelation(PKValue, RttiType, AObject.ClassName, AObject);
  GetStrategy.Delete(RttiType, AObject, _table, fields);
  GetLogger.ExitLevel('Delete');
end;

procedure TSession.DeleteAll(AClassType: TClass);
var
  _table: string;
  // _child_type, _type: TRttiType;
  // fields: TArray<TdormFieldMapping>;
begin
  _table := GetTableName(AClassType.ClassName);
  GetStrategy.DeleteAll(_table);
end;

procedure TSession.DeleteHasManyRelation(APKValue: TValue; ARttiType: TRttiType;
  AClassName: string; AObject: TObject);
var
  _child_field_name, _child_class_name: string;
  _has_many: TSuperArray;
  v: TValue;
  // , _pk_value: TValue;
  // O: TObject;
  _child_type: TRttiType;
  i: Integer;
  Coll: TdormCollection;
begin
  GetLogger.EnterLevel('has_many ' + AClassName);
  _has_many := FMapping.O['mapping'].O[AClassName].A['has_many'];
  if assigned(_has_many) then
  begin
    GetLogger.Debug('Deleting has_many for ' + AClassName);
    for i := 0 to _has_many.Length - 1 do
    begin
      v := TdormUtils.GetField(AObject, _has_many[i].AsObject.s['name']);
      _child_class_name := _has_many[i].AsObject.s['class_name'];
      _child_type := FCTX.FindType(Qualified(_child_class_name));
      if not assigned(_child_type) then
        raise Exception.Create('Unknown type ' + _child_class_name);
      _child_field_name := _has_many[i].AsObject.s['child_field_name'];
      Coll := TdormCollection(v.AsObject); // if the relation is LazyLoad...
      { todo: The has_many rows should be deleted also if they are lazy_loaded }
      { todo: optimize the delete? }
      if assigned(Coll) then
        Coll.ForEach<TObject>(
          procedure(O: TObject)
          begin
            Delete(O);
          end);
    end;
  end;
  GetLogger.ExitLevel('has_many ' + AClassName);
end;

destructor TSession.Destroy;
begin
  if GetStrategy.InTransaction then
    GetStrategy.Rollback;
  // FIdentityMap.Clear;
  // FIdentityMap.Free;
  FUOWInsert.Free;
  FUOWUpdate.Free;
  FUOWDelete.Free;
  FDictTables.Free;
  FDictMapping.Free;
  FPersistStrategy := nil;
  inherited;
end;

procedure TSession.DoDeleteValidation(AObject: TObject);
begin
  if AObject is TdormObject then
  begin
    if not(TdormObject(AObject).Validate and TdormObject(AObject).DeleteValidate)
    then
      raise EdormException.Create(TdormObject(AObject).ValidationErrors);
  end;
end;

procedure TSession.DoInsertValidation(AObject: TObject);
begin
  if AObject is TdormObject then
  begin
    if not(TdormObject(AObject).Validate and TdormObject(AObject).InsertValidate)
    then
      raise EdormException.Create(TdormObject(AObject).ValidationErrors);
  end;
end;

procedure TSession.DoOnBeforeInsert(AObject: TObject);
begin
  if AObject is TdormObject then
    TdormObject(AObject).OnBeforeInsert;
end;

procedure TSession.DoOnBeforeUpdate(AObject: TObject);
begin
  if AObject is TdormObject then
    TdormObject(AObject).OnBeforeUpdate;
end;

procedure TSession.DoOnBeforeDelete(AObject: TObject);
begin
  if AObject is TdormObject then
    TdormObject(AObject).OnBeforeDelete;
end;

procedure TSession.DoOnAfterLoad(AObject: TObject);
begin
  if AObject is TdormObject then
    TdormObject(AObject).OnAfterLoad;
end;

procedure TSession.DoUpdateValidation(AObject: TObject);
begin
  if AObject is TdormObject then
  begin
    if not(TdormObject(AObject).Validate and TdormObject(AObject).UpdateValidate)
    then
      raise EdormException.Create(TdormObject(AObject).ValidationErrors);
  end;
end;

procedure TSession.Extract(AOID: string);
begin
  // FIdentityMap.Extract(AOID);
end;

function TSession.FindOne(AItemClassInfo: PTypeInfo; Criteria: TdormCriteria;
FreeCriteria: Boolean): TObject;
var
  Coll: TdormCollection;
begin
  Result := nil;
  Coll := List(AItemClassInfo, Criteria, FreeCriteria);
  try
    if Coll.Count > 1 then
      raise EdormException.CreateFmt
        ('FindOne MUST return one, and only one, record. Returned %d instead',
        [Coll.Count]);
    if Coll.Count = 1 then
      Result := Coll.Extract(0);
    // Non posso usare "as" per un buig nel compilatore :-(
  finally
    Coll.Free;
  end;
end;

function TSession.FindOne<T>(Criteria: TdormCriteria; FreeCriteria: Boolean): T;
var
  Coll: TdormCollection;
begin
  Coll := List<T>(Criteria, FreeCriteria);
  try
    if Coll.Count <> 1 then
      raise EdormException.CreateFmt
        ('FindOne MUST return one, and only one, record. Returned %d instead',
        [Coll.Count]);
    Result := T(Coll.Extract(0));
    // Non posso usare "as" per un buig nel compilatore :-(
  finally
    Coll.Free;
  end;
end;

function TSession.GetLogger: IdormLogger;
begin
  Result := FLogger;
end;

function TSession.GetMapping: ISuperObject;
begin
  Result := FMapping.Clone;
end;

function TSession.GetPackageName(const AClassName: string): string;
var
  O: ISuperObject;
begin
  O := FMapping.O['mapping'].O[AClassName];
  if assigned(O) then
    Result := O.s['package']
  else
    raise EdormException.CreateFmt('Invalid mapping for [%s]', [AClassName]);
end;

function TSession.GetStrategy: IdormPersistStrategy;
var
  T: TRttiType;
begin
  if not assigned(FPersistStrategy) then
  begin
    T := FCTX.FindType(FMapping.O['persistence'].O[GetEnv].s
      ['database_adapter']);
    if assigned(T) then
    begin
      if Supports(T.AsInstance.MetaclassType, IdormPersistStrategy) then
      begin
        Supports(T.AsInstance.MetaclassType.Create,
          IdormPersistStrategy, Result);
        FPersistStrategy := Result;
        FPersistStrategy.SetLogger(FLogger);
      end
      else
        raise Exception.Create('Adapter does not support IdormPersistStrategy');
    end
    else
      raise Exception.Create('Adapter not found');
  end
  else
    Result := FPersistStrategy;
end;

function TSession.GetTableMapping(AClassName: string)
  : TArray<TdormFieldMapping>;
var
  i: Integer;
begin
  if not FDictMapping.TryGetValue(AClassName, Result) then
  begin
    SetLength(Result, FMapping.O['mapping'].O[AClassName].A['fields']
      .Length + 1);
    Result[0].parseFieldMapping(FMapping.O['mapping'].O[AClassName].O
      ['id'], true);
    for i := 1 to FMapping.O['mapping'].O[AClassName].A['fields'].Length do
      Result[i].parseFieldMapping(FMapping.O['mapping'].O[AClassName].A
        ['fields'][i - 1]);
    FDictMapping.Add(AClassName, Result);
  end;
end;

function TSession.GetTableName(AClassName: string): string;
var
  q: string;
begin
  q := AClassName;
  if not FDictTables.TryGetValue(q, Result) then
  begin
    Result := FMapping.O['mapping'].O[q].s['table'];
    FDictTables.Add(q, Result);
  end;
end;

function TSession.GetPersistentClassesName(WithPackage: Boolean): TList<string>;
var
  A: TSuperArray;
  i: Integer;
begin
  Result := TList<string>.Create;
  A := FMapping.O['persistence'].A['persistent_classes'];
  if A.Length = 0 then
    EdormException.Create('persistent_classes non present or not valid');
  for i := 0 to A.Length - 1 do
    if WithPackage then
      Result.Add(FMapping.O['mapping'].O[A.s[i]].s['package'] + '.' + A.s[i])
    else
      Result.Add(A.s[i]);
end;

function TSession.GetEnv: string;
begin
  Result := EnvironmentNames[ord(FEnvironment)];
end;

function TSession.GetFieldNameFromAttributeName(_table_mapping
  : TArray<TdormFieldMapping>; _child_class_name, _child_field_name
  : string): string;
var
  f: TdormFieldMapping;
begin
  for f in _table_mapping do
    if SameText(f.name, _child_field_name) then
      Exit(f.field);
  raise EdormException.CreateFmt('Cannot find mapping %s.%s',
    [_child_class_name, _child_field_name]);
end;

procedure TSession.LazyLoadFor(const APropertyName: string; AObject: TObject);
var
  PKValue: TValue;
  RttiType: TRttiType;
  // _class_name: string;
  // fields: TArray<TdormFieldMapping>;
begin
  RttiType := FCTX.GetType(AObject.ClassInfo);
  PKValue := GetPKValue(RttiType, GetTableMapping(AObject.ClassName), AObject);
  LoadHasManyRelationByPropertyName(PKValue, RttiType, AObject.ClassName,
    APropertyName, AObject);
  LoadHasOneRelationByPropertyName(PKValue, RttiType, AObject.ClassName,
    APropertyName, AObject);
end;

function TSession.List(AdormSearchCriteria: IdormSearchCriteria)
  : TdormCollection;
var
  rt: TRttiType;
  _table: string;
  _fields: TArray<TdormFieldMapping>;
  _type_info: PTypeInfo;
  searcher_classname: string;
begin
  _type_info := AdormSearchCriteria.GetItemClassInfo;
  searcher_classname := TObject(AdormSearchCriteria).ClassName;
  GetLogger.EnterLevel(searcher_classname);
  rt := FCTX.GetType(_type_info);
  _table := GetTableName(rt.ToString);
  _fields := GetTableMapping(rt.ToString);
  Result := FPersistStrategy.List(rt, _table, _fields, AdormSearchCriteria);
  Result.SetOwnsObjects(true);
  GetLogger.ExitLevel(searcher_classname);
end;

function TSession.List<T>(Criteria: TdormCriteria; FreeCriteria: Boolean)
  : TdormCollection;
begin
  Result := List(TypeInfo(T), Criteria);
  if FreeCriteria then
    FreeAndNil(Criteria);
end;

function TSession.ListAll<T>: TdormCollection;
var
  _table: string;
begin
  _table := GetTableName(T.ClassName);
  Result := List<T>(TdormCriteria.Create);
end;

function TSession.Load(ATypeInfo: PTypeInfo; const Value: TValue): TObject;
var
  rt: TRttiType;
  _table: string;
  _fields: TArray<TdormFieldMapping>;
begin
  rt := FCTX.GetType(ATypeInfo);
  GetLogger.EnterLevel('Load ' + rt.ToString);
  _table := GetTableName(rt.ToString);
  _fields := GetTableMapping(rt.ToString);
  Result := FPersistStrategy.Load(rt, _table, _fields, Value);
  if assigned(Result) then
  begin
    LoadBelongsToRelation(GetPKValue(rt, _fields, Result), rt,
      rt.ToString, Result);
    LoadHasManyRelation(GetPKValue(rt, _fields, Result), rt,
      rt.ToString, Result);
    LoadHasOneRelation(GetPKValue(rt, _fields, Result), rt,
      rt.ToString, Result);
  end;
  DoOnAfterLoad(Result);
  GetLogger.ExitLevel('Load ' + rt.ToString);
end;

// function TSession.Load<T>(const Value: string; AObject: T): Boolean;
// begin
// Result := Load(TypeInfo(T), Value, AObject);
// end;

function TSession.Load<T>(const Value: TValue): T;
begin
  Result := T(Load(TypeInfo(T), Value));
end;

procedure TSession.LoadHasManyRelation(APKValue: TValue; ARttiType: TRttiType;
AClassName: string; AObject: TObject);
var
  _has_many: TSuperArray;
  i: Integer;
begin
  GetLogger.EnterLevel('has_many ' + AClassName);
  _has_many := FMapping.O['mapping'].O[AClassName].A['has_many'];
  if assigned(_has_many) then
  begin
    for i := 0 to _has_many.Length - 1 do
    begin
      if not _has_many[i].B['lazy_load'] then
        LoadHasManyRelationByPropertyName(APKValue, ARttiType, AClassName,
          _has_many[i].AsObject.s['name'], AObject);
    end;
  end;
  GetLogger.ExitLevel('has_many ' + AClassName);
end;

procedure TSession.LoadHasManyRelationByPropertyName(APKValue: TValue;
ARttiType: TRttiType; AClassName: string; APropertyName: string;
var AObject: TObject);
var
  _has_many: TSuperArray;
  _child_field_name, _child_class_name, _child_db_field_name: string;
  v: TValue;
  List: TdormCollection;
  _child_type: TRttiType;
  SearchChildCriteria: IdormSearchCriteria;
  i: Integer;
  _table_mapping: TArray<TdormFieldMapping>;
begin
  GetLogger.Debug('Loading HAS_MANY for ' + AClassName + '.' + APropertyName);
  _has_many := FMapping.O['mapping'].O[AObject.ClassName].A['has_many'];
  if assigned(_has_many) then
  begin
    _table_mapping := GetTableMapping(AClassName);
    i := GetRelationMappingIndexByPropertyName(_has_many, APropertyName);
    if i >= 0 then
    begin
      v := TdormUtils.GetField(AObject, _has_many[i].AsObject.s['name']);
      _child_class_name := _has_many[i].AsObject.s['class_name'];
      _child_type := FCTX.FindType(Qualified(_child_class_name));
      if not assigned(_child_type) then
        raise Exception.Create('Unknown type ' + _child_class_name);
      _child_field_name := _has_many[i].AsObject.s['child_field_name'];
      _child_db_field_name := GetFieldNameFromAttributeName
        (GetTableMapping(_child_class_name), _child_class_name,
        _child_field_name);
      SearchChildCriteria := CreateChildLoaderSearch(_child_class_name,
        GetTableName(_child_class_name), _child_db_field_name,
        GetPKValue(ARttiType, _table_mapping, AObject));
      List := GetStrategy.List(_child_type, GetTableName(_child_class_name),
        GetTableMapping(_child_class_name), SearchChildCriteria);
      v := TValue.From<TdormCollection>(List);
      TdormUtils.SetField(AObject, _has_many[i].AsObject.s['name'], v);
      LoadRelations(v.AsObject as TdormCollection);
    end
    else
      raise Exception.Create('Unknown property name ' + APropertyName);
  end;
end;

procedure TSession.LoadHasOneRelation(APKValue: TValue; ARttiType: TRttiType;
AClassName: string; AObject: TObject);
var
  _has_one: TSuperArray;
  i: Integer;
begin
  GetLogger.EnterLevel('has_one ' + AClassName);
  _has_one := FMapping.O['mapping'].O[AClassName].A['has_one'];
  if assigned(_has_one) then
  begin
    for i := 0 to _has_one.Length - 1 do
    begin
      if not _has_one[i].B['lazy_load'] then
        LoadHasOneRelationByPropertyName(APKValue, ARttiType, AClassName,
          _has_one[i].AsObject.s['name'], AObject);
    end;
  end;
  GetLogger.ExitLevel('has_one ' + AClassName);
end;

procedure TSession.LoadBelongsToRelation(APKValue: TValue; ARttiType: TRttiType;
AClassName: string; AObject: TObject);
var
  // _child_field_name, _child_class_name: string;
  _belongs_to: TSuperArray;
  // v, _pk_value: TValue;
  // List: IList;
  // O: TObject;
  // _child_type: TRttiType;
  // SearchChildCriteria: IdormSearchCriteria;
  i: Integer;
begin
  GetLogger.EnterLevel('belongs_to ' + AClassName);
  _belongs_to := FMapping.O['mapping'].O[AClassName].A['belongs_to'];
  if assigned(_belongs_to) then
  begin
    for i := 0 to _belongs_to.Length - 1 do
    begin
      if not _belongs_to[i].B['lazy_load'] then
        LoadBelongsToRelationByPropertyName(APKValue, ARttiType, AClassName,
          _belongs_to[i].AsObject.s['name'], AObject);
    end;
  end;
  GetLogger.ExitLevel('belongs_to ' + AClassName);
end;

procedure TSession.LoadHasOneRelationByPropertyName(APKValue: TValue;
ARttiType: TRttiType; AClassName, APropertyName: string; var AObject: TObject);
var
  _has_one: TSuperArray;
  _child_class_name: string;
  v: TValue;
  _child_type: TRttiType;
  i: Integer;
  _parent_field_key_value: TValue;
  _child_field_name: string;
begin
  GetLogger.Debug('Loading HAS_ONE for ' + AClassName + '.' + APropertyName);
  _has_one := FMapping.O['mapping'].O[AObject.ClassName].A['has_one'];
  if assigned(_has_one) then
  begin
    i := GetRelationMappingIndexByPropertyName(_has_one, APropertyName);
    if i >= 0 then
    begin
      if not _has_one[i].B['lazy_load'] then
      begin
        _child_class_name := _has_one[i].AsObject.s['class_name'];
        _child_type := FCTX.FindType(Qualified(_child_class_name));
        _child_field_name := _has_one[i].AsObject.s['child_field_name'];
        if not assigned(_child_type) then
          raise Exception.Create('Unknown type ' + _child_class_name);
        if _child_field_name = EmptyStr then
          raise Exception.Create('Empty child_field_name for ' +
            _child_class_name);

        v := FindOne(_child_type.Handle,
          TdormCriteria.NewCriteria(_child_field_name,
          TdormCompareOperator.Equal, APKValue), true);
        // v := Load(FCTX.FindType(Qualified(_child_class_name)).Handle, APKValue);
        TdormUtils.SetField(AObject, _has_one[i].AsObject.s['name'], v);
      end;
    end
    else
      raise Exception.Create('Unknown property name ' + APropertyName);
  end;
end;

procedure TSession.LoadRelations(AList: TdormCollection);
var
  i: Integer;
begin
  for i := 0 to AList.Count - 1 do
    LoadRelations(AList.GetItem(i));
end;

function TSession.OIDIsSet(Obj: TObject): Boolean;
var
  rt: TRttiType;
  pk_value: TValue;
begin
  rt := FCTX.GetType(Obj.ClassType);
  pk_value := GetPKValue(rt, GetTableMapping(rt.ToString), Obj);
  Result := not GetStrategy.IsNullKey(pk_value);
end;

procedure TSession.LoadRelations(AObject: TObject);
var
  rt: TRttiType;
  _table: string;
  _fields: TArray<TdormFieldMapping>;
begin
  if assigned(AObject) then
  begin
    rt := FCTX.GetType(AObject.ClassType);
    _table := GetTableName(rt.ToString);
    _fields := GetTableMapping(rt.ToString);
    LoadBelongsToRelation(GetPKValue(rt, _fields, AObject), rt,
      rt.ToString, AObject);
    LoadHasManyRelation(GetPKValue(rt, _fields, AObject), rt,
      rt.ToString, AObject);
    LoadHasOneRelation(GetPKValue(rt, _fields, AObject), rt,
      rt.ToString, AObject);
  end;
end;

procedure TSession.LoadBelongsToRelationByPropertyName(APKValue: TValue;
ARttiType: TRttiType; AClassName, APropertyName: string; var AObject: TObject);
var
  _belongs_to: TSuperArray;
  _belong_class_name: string;
  v: TValue;
  _belong_type: TRttiType;
  i: Integer;
  _belong_field_key_value: TValue;
begin
  GetLogger.Debug('Loading BELONGS_TO for ' + AClassName + '.' + APropertyName);
  _belongs_to := FMapping.O['mapping'].O[AObject.ClassName].A['belongs_to'];
  if assigned(_belongs_to) then
  begin
    i := GetRelationMappingIndexByPropertyName(_belongs_to, APropertyName);
    if i >= 0 then
    begin
      _belong_class_name := _belongs_to[i].AsObject.s['class_name'];
      _belong_type := FCTX.FindType(Qualified(_belong_class_name));
      if not assigned(_belong_type) then
        raise Exception.Create('Unknown type ' + _belong_class_name);
      _belong_field_key_value := TdormUtils.GetField(AObject,
        _belongs_to[i].AsObject.s['ref_field_name']);
      v := Load(FCTX.FindType(Qualified(_belong_class_name)).Handle,
        _belong_field_key_value);
      TdormUtils.SetField(AObject, _belongs_to[i].AsObject.s['name'], v);
      LoadRelations(v.AsObject);
    end
    else
      raise Exception.Create('Unknown property name ' + APropertyName);
  end;
end;

function TSession.Qualified(const AClassName: string): string;
begin
  Result := GetPackageName(AClassName) + '.' + AClassName;
end;

procedure TSession.Rollback;
begin
  GetStrategy.Rollback;
  GetLogger.ExitLevel('TSession.Rollback');
end;

function TSession.Save(AObject: TObject; SaveType: TdormSaveType): TValue;
var
  _type: TRttiType;
  _table, _class_name: string; // _child_field_name, _child_class_name,
  fields: TArray<TdormFieldMapping>;
  _pk_value: TValue;
begin
  GetLogger.EnterLevel(_class_name);
  DoInsertValidation(AObject);
  DoOnBeforeInsert(AObject);
  _type := FCTX.GetType(AObject.ClassInfo);
  _class_name := _type.ToString;
  _table := GetTableName(_class_name);
  fields := GetTableMapping(_class_name);
  _pk_value := GetPKValue(_type, fields, AObject);

  if GetStrategy.IsNullKey(_pk_value) then
  begin
    FLogger.Info('Inserting ' + AObject.ClassName);
    GetStrategy.Insert(_type, AObject, _table, fields);
    InsertHasManyRelation(GetPKValue(_type, fields, AObject), _type,
      _class_name, AObject);
    InsertHasOneRelation(GetPKValue(_type, fields, AObject), _type,
      _class_name, AObject);
  end
  else
    raise EdormException.CreateFmt('Cannot insert object with an ID [%s]',
      [_class_name]);
  GetLogger.ExitLevel(_class_name);
end;

procedure TSession.Save(dormUOW: TdormUOW);
var
  c: TdormCollection;
begin
  c := dormUOW.GetUOWInsert;
  InsertCollection(c);
  c := dormUOW.GetUOWUpdate;
  UpdateCollection(c);
  c := dormUOW.GetUOWDelete;
  DeleteCollection(c);
end;

procedure TSession.SetLazyLoadFor(ATypeInfo: PTypeInfo;
const APropertyName: string; const Value: Boolean);
var
  i: Integer;
  RttiType: TRttiType;
  _has_many: TSuperArray;
begin
  RttiType := FCTX.GetType(ATypeInfo);
  _has_many := FMapping.O['mapping'].O[RttiType.ToString].A['has_many'];
  for i := 0 to _has_many.Length - 1 do
  begin
    if CompareText(_has_many[i].s['name'], APropertyName) = 0 then
    begin
      _has_many[i].B['lazy_load'] := Value;
      Break;
    end;
  end;
end;

procedure TSession.InsertCollection(Collection: TdormCollection);
var
  // Obj: TObject;
  i: Integer;
begin
  for i := 0 to Collection.Count - 1 do
    Save(Collection.GetItem(i));
end;

procedure TSession.InsertHasManyRelation(APKValue: TValue; ARttiType: TRttiType;
AClassName: string; AObject: TObject);
var
  _child_field_name, _child_class_name: string;
  _has_many: TSuperArray;
  v: TValue; // , _pk_value
  List: TdormCollection;
  // O: TObject;
  _child_type: TRttiType;
  i, j: Integer;
  // prop: TRttiProperty;
begin
  GetLogger.EnterLevel('has_many ' + AClassName);
  _has_many := FMapping.O['mapping'].O[AClassName].A['has_many'];
  if assigned(_has_many) then
  begin
    GetLogger.Debug('Saving has_many for ' + AClassName);
    for i := 0 to _has_many.Length - 1 do
    begin
      // prop := ARttiType.GetProperty(_has_many[i].AsObject.s['name']);
      // if not assigned(prop) then
      // raise EdormException.Create('Cannot find ' + AClassName + '.' + _has_many[i].AsObject.s['name']);
      // v := prop.GetValue(AObject);
      v := TdormUtils.GetField(AObject, _has_many[i].AsObject.s['name']);

      _child_class_name := _has_many[i].AsObject.s['class_name'];
      GetLogger.Debug('-- Inspecting for ' + _child_class_name);
      _child_type := FCTX.FindType(Qualified(_child_class_name));
      if not assigned(_child_type) then
        raise Exception.Create('Unknown type ' + _child_class_name);
      _child_field_name := _has_many[i].AsObject.s['child_field_name'];

      List := TdormCollection(v.AsObject);
      if assigned(List) then
        for j := 0 to List.Count - 1 do
        begin
          GetLogger.Debug('-- Saving ' + _child_type.QualifiedName);
          GetLogger.Debug('----> Setting property ' + _child_field_name);
          TdormUtils.SetField(List[j], _child_field_name, APKValue);
          Save(List[j]);
        end;
    end;
  end;
  GetLogger.ExitLevel('has_many ' + AClassName);
end;

procedure TSession.InsertHasOneRelation(APKValue: TValue; ARttiType: TRttiType;
AClassName: string; AObject: TObject);
var
  _child_field_name, _child_class_name: string;
  _has_one: TSuperArray;
  v: TValue;
  List: TdormCollection;
  _child_type: TRttiType;
  i, j: Integer;
  Obj: TObject;
begin
  GetLogger.EnterLevel('has_one ' + AClassName);
  _has_one := FMapping.O['mapping'].O[AClassName].A['has_one'];
  if assigned(_has_one) then
  begin
    GetLogger.Debug('Saving _has_one for ' + AClassName);
    for i := 0 to _has_one.Length - 1 do
    begin
      v := TdormUtils.GetField(AObject, _has_one[i].AsObject.s['name']);
      _child_class_name := _has_one[i].AsObject.s['class_name'];
      GetLogger.Debug('-- Inspecting for ' + _child_class_name);
      _child_type := FCTX.FindType(Qualified(_child_class_name));
      if not assigned(_child_type) then
        raise Exception.Create('Unknown type ' + _child_class_name);
      _child_field_name := _has_one[i].AsObject.s['child_field_name'];

      Obj := v.AsObject;
      if assigned(Obj) then
      begin
        GetLogger.Debug('-- Saving ' + _child_type.QualifiedName);
        GetLogger.Debug('----> Setting property ' + _child_field_name);
        TdormUtils.SetField(Obj, _child_field_name, APKValue);
        Save(Obj);
      end;
    end;
  end;
  GetLogger.ExitLevel('has_one ' + AClassName);
end;

procedure TSession.StartTransaction;
begin
  GetLogger.EnterLevel('TSession.StartTransaction');
  GetStrategy.StartTransaction;
end;

function TSession.Strategy: IdormPersistStrategy;
begin
  Result := GetStrategy;
end;

procedure TSession.Update(AObject: TObject);
var
  // _child_type,
  _type: TRttiType;
  _table, _class_name: string; // _child_field_name, _child_class_name,
  // json, _map: ISuperObject;
  // m: TdormFieldMapping;
  fields: TArray<TdormFieldMapping>;
  // i: Integer;
  // _has_many: TSuperArray;
  // v,
  _pk_value: TValue;
  // List: IList;
  // O: TObject;
begin
  GetLogger.EnterLevel(_class_name);
  DoUpdateValidation(AObject);
  DoOnBeforeUpdate(AObject);
  _type := FCTX.GetType(AObject.ClassInfo);
  _class_name := _type.ToString;
  _table := GetTableName(_class_name);
  fields := GetTableMapping(_class_name);
  _pk_value := GetPKValue(_type, fields, AObject);

  if not GetStrategy.IsNullKey(_pk_value) then
  begin
    FLogger.Info('Updating ' + AObject.ClassName);
    GetStrategy.Update(_type, AObject, _table, fields);
    // UpdateHasManyRelation(GetPKValue(_type, fields, AObject), _type,
    // _class_name, AObject);
  end
  else
    raise EdormException.CreateFmt('Cannot update object without an ID [%s]',
      [_class_name]);
  GetLogger.ExitLevel(_class_name);
end;

procedure TSession.UpdateCollection(Collection: TdormCollection);
var
  i: Integer;
begin
  for i := 0 to Collection.Count - 1 do
    Update(Collection.GetItem(i));
end;

procedure TSession.DeleteCollection(Collection: TdormCollection);
var
  i: Integer;
begin
  for i := 0 to Collection.Count - 1 do
    Delete(Collection.GetItem(i));
end;

function TSession.List(AItemClassInfo: PTypeInfo; Criteria: TdormCriteria;
FreeCriteria: Boolean): TdormCollection;
var
  _table: string;
  SQL: string;
  CritItem: TdormCriteriaItem;
  i: Integer;
  Mapping: TArray<TdormFieldMapping>;
  fm: TdormFieldMapping;
  function GetFieldMappingByAttribute(AttributeName: string): TdormFieldMapping;
  var
    fm: TdormFieldMapping;
  begin
    for fm in Mapping do
      if fm.name = AttributeName then
        Exit(fm);
    raise EdormException.CreateFmt('Unknown field attribute %s',
      [AttributeName]);
  end;

begin
  _table := GetTableName(string(AItemClassInfo.name));
  if Criteria.Count > 0 then
    SQL := 'SELECT * FROM ' + _table + ' WHERE '
  else
    SQL := 'SELECT * FROM ' + _table + ' ';
  Mapping := GetTableMapping(string(AItemClassInfo.name));

  for i := 0 to Criteria.Count - 1 do
  begin
    CritItem := Criteria.GetCriteria(i);
    if i > 0 then
      case CritItem.LogicRelation of
        lrAnd:
          SQL := SQL + ' AND ';
        lrOr:
          SQL := SQL + ' OR ';
      end;
    fm := GetFieldMappingByAttribute(CritItem.Attribute);
    SQL := SQL + fm.field;
    case CritItem.CompareOperator of
      Equal:
        SQL := SQL + ' = ';
      GreaterThan:
        SQL := SQL + ' > ';
      LowerThan:
        SQL := SQL + ' < ';
      GreaterOrEqual:
        SQL := SQL + ' >= ';
      LowerOrEqual:
        SQL := SQL + ' <= ';
      Different:
        SQL := SQL + ' != ';
    end;

    if fm.field_type = 'string' then
      SQL := SQL + '''' + CritItem.Value.AsString + '''';
    if fm.field_type = 'integer' then
      SQL := SQL + inttostr(CritItem.Value.AsInteger);
    if fm.field_type = 'boolean' then
      SQL := SQL + BoolToStr(CritItem.Value.AsBoolean);

  end;
  Result := List(TdormSimpleSearchCriteria.Create(AItemClassInfo, SQL));
  if FreeCriteria then
    FreeAndNil(Criteria);
end;

{ TdormSimpleSearchCriteria }

constructor TdormSimpleSearchCriteria.Create(AItemClassInfo: PTypeInfo;
ASQL: string);
begin
  inherited Create;
  FSQL := ASQL;
  FItemClassInfo := AItemClassInfo;
end;

function TdormSimpleSearchCriteria.GetItemClassInfo: PTypeInfo;
begin
  Result := FItemClassInfo;
end;

function TdormSimpleSearchCriteria.GetSQL: string;
begin
  Result := FSQL;
end;

{ TdormCriteria }

function TdormCriteria.Add(const Attribute: string;
CompareOperator: TdormCompareOperator; Value: TValue;
LogicRelation: TdormLogicRelation): TdormCriteria;
var
  Item: TdormCriteriaItem;
begin
  Item := TdormCriteriaItem.Create;
  Item.Attribute := Attribute;
  Item.CompareOperator := CompareOperator;
  Item.Value := Value;
  Item.LogicRelation := LogicRelation;
  FItems.Add(Item);
  Result := self;
end;

function TdormCriteria.AddOr(const Attribute: string;
CompareOperator: TdormCompareOperator; Value: TValue): TdormCriteria;
begin
  Result := Add(Attribute, CompareOperator, Value, lrOr);
end;

function TdormCriteria.AddAnd(const Attribute: string;
CompareOperator: TdormCompareOperator; Value: TValue): TdormCriteria;
begin
  Result := Add(Attribute, CompareOperator, Value, lrAnd);
end;

procedure TdormCriteria.Clear;
begin
  FItems.Clear;
end;

function TdormCriteria.Count: Integer;
begin
  Result := FItems.Count;
end;

constructor TdormCriteria.Create;
begin
  inherited;
  FItems := TObjectList<TdormCriteriaItem>.Create(true);
end;

destructor TdormCriteria.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TdormCriteria.GetCriteria(const index: Integer): TdormCriteriaItem;
begin
  Result := FItems[index];
end;

class function TdormCriteria.NewCriteria(const Attribute: string;
CompareOperator: TdormCompareOperator; Value: TValue): TdormCriteria;
begin
  Result := TdormCriteria.Create;
  Result.Add(Attribute, CompareOperator, Value);
end;

{ TdormSearch }

constructor TdormSearch.Create(AItemClassInfo: PTypeInfo; ASQL: string);
begin
  inherited;
  FParameters := TdormParameters.Create(true);
end;

destructor TdormSearch.Destroy;
begin
  FParameters.Free;
  inherited;
end;

end.
