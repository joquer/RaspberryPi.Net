#Requires -Version 3.0
param(
    [string]$databaseServer = "cpm-dev-db01.devid.local",
    [string]$databaseName)

$root = Split-Path $MyInvocation.MyCommand.Path

$sqlVars = "dbname=$databaseName"

$sqlPath = Join-Path $root "SQL\delete_db.sql"
Invoke-Sqlcmd -Verbose -ServerInstance $databaseServer -AbortOnError -ConnectionTimeout 10 -InputFile $sqlPath -Variable $sqlVars
