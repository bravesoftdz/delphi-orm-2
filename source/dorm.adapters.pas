unit dorm.adapters;

interface

{
  This unit include (links) all the persistence adapter enabled in the dorm.inc file.
  If you want to use an adapter, do not include statically the unit but enable it
  in the dorm.inc file, then include only THIS file
}
{$I DORM.INC}

uses
  SysUtils
{$IFDEF LINK_FIREBIRD_ADAPTER}
    ,
  dorm.adapter.firebird
{$ENDIF}
{$IFDEF LINK_INTERBASE_ADAPTER}
    ,
  dorm.adapter.interbase
{$ENDIF}
{$IFDEF LINK_FIREBIRDUIB_ADAPTER}
    ,
  dorm.adapter.UIB.firebird
{$ENDIF}
{$IFDEF LINK_INTERBASEUIB_ADAPTER}
    ,
  dorm.adapter.UIB.interbase
{$ENDIF}
{$IFDEF LINK_SQLITE3_ADAPTER}
    ,
  dorm.adapter.sqlite3
{$ENDIF}
{$IFDEF LINK_SQLSERVER_ADAPTER}
  SQLServer is not supported in this version of dorm,
  dorm.adapter.sqlserver9
{$ENDIF}
{$IFDEF LINK_SQLSERVERDEVART_ADAPTER}
  SQLServer is not supported in this version of dorm,
  dorm.adapter.sqlserverdevart
{$ENDIF}
    ;
{ ************************ WARNING ************************ }
{ You have to enable at least ONE adapter in file dorm.INC }
{ ************************ WARNING ************************ }

implementation

end.
