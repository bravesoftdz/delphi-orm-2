unit dorm.Commons;

interface

uses
  RTTI,
  Classes,
  superobject,
  Generics.Collections,
  SysUtils,
  TypInfo,
  dorm.Collections;

type
  EdormException = class(Exception)

  end;

  TdormEnvironment = (deDevelopment, deTest, deRelease);
  TdormObjectOwner = (ooItself, ooParent);
  TdormIndexType = (itNone, itIndex, itUnique);
  TdormSaveType = (stAllGraph, stSingleObject);
  TdormKeyType = (ktInteger, ktString);
  TdormCompareOperator = (
    Equal, GreaterThan, LowerThan, GreaterOrEqual, LowerOrEqual, Different
    );
  TdormLogicRelation = (lrAnd, lrOr);
  TdormCriteriaItem = class;

  TdormInterfacedObject = class(TInterfacedObject)
    constructor Create; virtual;
  end;

  IdormLogger = interface
    ['{3501FE53-3781-4F6F-BE6C-80A2309D8D94}']
    procedure EnterLevel(const Value: string);
    procedure ExitLevel(const Value: string);
    procedure Error(const Value: string);
    procedure Warning(const Value: string);
    procedure Info(const Value: string);
    procedure Debug(const Value: string);
  end;

  IdormSearchCriteria = interface
    ['{7F19727A-8113-43F0-8211-A3EFB47E57EB}']
    function GetSQL: string;
    function GetItemClassInfo: PTypeInfo;
  end;

  TdormFieldMapping = record
    pk: boolean;
    name: string;
    field: string;
    field_type: string;
    default_value: string;
    size: Cardinal;
    precision: Cardinal;
    index_type: TdormIndexType;
    procedure parseFieldMapping(json: ISuperObject; IsPK: boolean = false);
    function ToString: string;
  end;

  IdormKeysGenerator = interface
    ['{476D88A6-E7A1-48A2-8673-C2B646A2E7F4}']
    function NewStringKey(const Entity: string): string;
    function NewIntegerKey(const Entity: string): UInt64;
  end;

  TdormListEnumerator = class(TEnumerator<TObject>)
  private
    FList: TdormCollection;
    FCurrent: Integer;
  protected
    function DoGetCurrent: TObject; override;
    function DoMoveNext: boolean; override;
  public
    constructor Create(AList: TdormCollection);
  end;

  IList = interface
    ['{2A1BCB3C-17A2-4F8D-B6FB-32B2A1BFE840}']
    function Add(const Value: TObject): Integer;
    function First: TObject;
    function Last: TObject;
    procedure Clear;
    function Count: Integer;
    function Remove(const Value: TObject): Integer;
    procedure Delete(index: Integer);
    procedure DeleteRange(AIndex, ACount: Integer);
    function contains(const Value: TObject): boolean;
    function IndexOf(const Value: TObject): Integer;
    function GetItem(index: Integer): TObject;
    procedure SetItem(index: Integer; const Value: TObject);
    function GetEnumerator: TdormListEnumerator;
  end;

  IdormPersistStrategy = interface
    ['{04A7F5C2-9B9B-4259-90C2-F23894189717}']
    function Insert(rtty_type: TRttiType; AObject: TObject; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>): TValue;
    function Update(rtty_type: TRttiType; AObject: TObject; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>): TValue;
    function Load(ARttiType: TRttiType; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>; const Value: Integer): TObject;
      overload;
    function Load(ARttiType: TRttiType; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>; const Value: TValue)
      : TObject; overload;
    function Load(ARttiType: TRttiType; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>; const Value: string;
      out AObject: TObject): boolean; overload;
    function List(ARttiType: TRttiType; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>;
      AdormSearchCriteria: IdormSearchCriteria): TdormCollection;
    function CreateChildLoaderSearch(AChildClassTypeInfo: PTypeInfo;
      AChildClassName, AChildTableName, AChildRelationField: string;
      APKValue: TValue): IdormSearchCriteria;
    function Delete(ARttiType: TRttiType; AObject: TObject; ATableName: string;
      AFieldsMapping: TArray<TdormFieldMapping>): TObject;
    procedure DeleteAll(ATableName: string);
    function Count(ATableName: string): Int64;
    function GetLastInsertID: Int64;
    procedure ConfigureStrategy(ConfigurationInfo: ISuperObject);
    procedure InitStrategy;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    function InTransaction: boolean;
    function IsNullKey(const Value: TValue): boolean;
    procedure SetLogger(ALogger: IdormLogger);
    function RawExecute(SQL: string): Int64;
  end;

  TdormCriteriaItem = class
  private
    FCompareOperator: TdormCompareOperator;
    FAttribute: string;
    FValue: TValue;
    FLogicRelation: TdormLogicRelation;
    procedure SetAttribute(const Value: string);
    procedure SetCompareOperator(const Value: TdormCompareOperator);
    procedure SetValue(const Value: TValue);
    procedure SetLogicRelation(const Value: TdormLogicRelation);
  public
    property Attribute: string read FAttribute write SetAttribute;
    property CompareOperator: TdormCompareOperator read FCompareOperator write SetCompareOperator;
    property Value: TValue read FValue write SetValue;
    property LogicRelation: TdormLogicRelation read FLogicRelation write SetLogicRelation;
  end;

function GetPKMappingIndex(const AMapping: TArray<TdormFieldMapping>): Integer;
function GetPKName(const AMapping: TArray<TdormFieldMapping>): string;
function GetPKValue(AType: TRttiType; const AMapping: TArray<TdormFieldMapping>;
  AObject: TObject): TValue;
function GetRelationMappingIndexByPropertyName(AHasManyMapping: TSuperArray;
  APropertyName: string): Integer;
// function CreateObject(ARttiType: TRttiType): TObject;

implementation

uses
  dorm,
  dorm.Utils;

// function CreateObject(ARttiType: TRttiType): TObject;
// begin
// Result := ARttiType.GetMethod('Create').Invoke(ARttiType.AsInstance.MetaclassType, []).AsObject;
// end;

function GetRelationMappingIndexByPropertyName(AHasManyMapping: TSuperArray;
  APropertyName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to AHasManyMapping.Length - 1 do
    if CompareText(AHasManyMapping[I].S['name'], APropertyName) = 0 then
    begin
      Result := I;
      Break;
    end;
end;

function GetPKValue(AType: TRttiType; const AMapping: TArray<TdormFieldMapping>;
  AObject: TObject): TValue;
begin
  Result := TdormUtils.GetField(AObject, GetPKName(AMapping));
end;

function GetPKName(const AMapping: TArray<TdormFieldMapping>): string;
begin
  Result := AMapping[GetPKMappingIndex(AMapping)].name;
end;

function GetPKMappingIndex(const AMapping: TArray<TdormFieldMapping>): Integer;
var
  I: Integer;
begin
  for I := 0 to Length(AMapping) - 1 do
    if AMapping[I].pk then
      Exit(I);
  Exit(-1);
end;

procedure TdormFieldMapping.parseFieldMapping(json: ISuperObject; IsPK: boolean);
var
  S: string;
begin
  pk := IsPK;
  name := json.S['name'];
  field := json.S['field'];
  size := json.I['size'];
  field_type := json.S['field_type'];
  default_value := json.S['default_value'];
  precision := json.I['precision'];
  index_type := itNone;
  S := json.S['index_type'];
  if SameText(S, 'index') then
    index_type := itIndex
  else if SameText(S, 'unique') then
    index_type := itUnique;
end;

function TdormFieldMapping.ToString: string;
begin
  Result := Format('PK: %s, name: %s, field: %s, field type: %s', [BoolToStr(pk, True), name,
    field, field_type]);
end;

{ TdormListEnumerator }

constructor TdormListEnumerator.Create(AList: TdormCollection);
begin
  inherited Create;
  FList := AList;
  FCurrent := -1;
end;

function TdormListEnumerator.DoGetCurrent: TObject;
begin
  if FCurrent > -1 then
    Result := FList.GetItem(FCurrent);
end;

function TdormListEnumerator.DoMoveNext: boolean;
begin
  Result := FList.Count > FCurrent + 1;
  if Result then
    FCurrent := FCurrent + 1;
end;

{ TdormInterfacedObject }

constructor TdormInterfacedObject.Create;
begin
  inherited Create;
end;

procedure TdormCriteriaItem.SetAttribute(const Value: string);
begin
  FAttribute := Value;
end;

procedure TdormCriteriaItem.SetCompareOperator(const Value: TdormCompareOperator);
begin
  FCompareOperator := Value;
end;

procedure TdormCriteriaItem.SetLogicRelation(const Value: TdormLogicRelation);
begin
  FLogicRelation := Value;
end;

procedure TdormCriteriaItem.SetValue(const Value: TValue);
begin
  FValue := Value;
end;

end.
