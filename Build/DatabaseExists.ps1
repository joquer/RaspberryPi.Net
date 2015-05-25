param (
  [Parameter(Mandatory=$True)]
  [string]$DatabaseServer,
  [Parameter(Mandatory=$True)]
  [string]$DatabaseName
)

$root = Split-Path $MyInvocation.MyCommand.Path

$results = Invoke-SqlCmd -Server $databaseServer -ConnectionTimeout 10 -QueryTimeout 10 -InputFile (Join-Path $root "SQL\DatabaseExists.sql") -Variable dbname=$databaseName
if ($results.FileExists -eq 1)
{
  exit 1
}
exit 0
