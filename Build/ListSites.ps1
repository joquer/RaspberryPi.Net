#Requires -Version 3.0
param (
  [int]$CutOffWeeks = 4,
  [string]$ServiceUrl = "",
  [string]$BuildType = "Dev",
  [string]$ProductAbbrev = "CMGA"
)


$root = Split-Path $MyInvocation.MyCommand.Path
. (Join-Path $root "LoadSiteManagerAssemblies.ps1")

$today = Get-Date

$cutOffDays = 7 * $cutOffWeeks
$cutOffDate = $today.AddDays(-$cutOffDays)

Write-Host "Listing Site Manager Sites"
Write-Host "  Cut Off Days :" $cutOffDays
Write-Host "  Cut Off Date :" $cutOffDate

if ($ServiceUrl -eq "")
{
  if ($Env:yggdrasilServiceUrl -eq $Null -or $Env:yggdrasilServiceUrl -eq "")
  {
     $ServiceUrl = ("net.tcp://cdi-dev-app01.devid.local:14265/CrimsonYggdrasil{0}" -f $buildType)
  }
  else
  {
    $ServiceUrl = $Env:yggdrasilServiceUrl
  }
}

$yggdrasilEnvironment = "Development"
if ($buildType -eq "QA") 
{
  $yggdrasilEnvironment = "QA"
}

$environment = Get-YggdrasilEnvironment -ServiceUrl $ServiceUrl | ? { $_.Name -eq $yggdrasilEnvironment }
if ($environment -eq $Null)
{
  Write-Host ("Environment " + $yggdrasilEnvironment + " Not Found")
  exit 1
}
Write-Host ("  Environment  : {0}({1})" -f $environment.Name, $environment.Id)

$product = Get-YggdrasilProduct -ServiceUrl $ServiceUrl | ? { $_.Abbreviation -eq $productAbbrev }
if ($product -eq $Null)
{
  Write-Host ("Product " + $productAbbrev + " Not Found")
  exit 1
}
$productId = $product.Id
Write-Host ("  Product      : {0} - {1}({2})" -f $product.Name, $productAbbrev, $productId)

$siteList = Get-YggdrasilSite  -ServiceUrl $ServiceUrl -ProductId $productId -EnvironmentId $environment.Id 
$serverList = Get-YggdrasilServer  -ServiceUrl $ServiceUrl 
$siteDefinitionList = Get-YggdrasilSiteDefinition  -ServiceUrl $ServiceUrl 
$memberList = Get-YggdrasilMember  -ServiceUrl $ServiceUrl

Write-Host "  Total Sites  :" $siteList.Length
Write-Host

$idleCount = 0
$errorCount = 0
foreach ($site in $siteList)
{
  $databaseServer = $serverList | ? { $_.Id -eq $site.DatabaseServerId }
  $webServer = $serverList | ? { $_.Id -eq $site.WebServerId }
  $siteDefinition = $siteDefinitionList | ? { $_.Name -eq $site.SiteDefinitionName }
  $member = $memberList | ? { $_.Id -eq $siteDefinition.MemberId }
  
  $databaseName = $site.DatabaseName
  
  & (Join-Path $root DatabaseExists.ps1) -DatabaseServer $databaseServer.Address -DatabaseName $databaseName
  
  if ($LastExitCode -eq 1)
  {
      $lastLoginDate = Get-Date
	  $loginQuery = Invoke-Sqlcmd -ServerInstance $databaseServer.Address -Database $databaseName -AbortOnError -ConnectionTimeout 10 -QueryTimeout 10 -Query "SELECT COUNT(*) as EventCount from [cpm].[UserEvents] where EventType = 0"
	  if ($loginQuery.EventCount -gt 1)
	  {
	    $loginQuery = Invoke-Sqlcmd -ServerInstance $databaseServer.Address -Database $databaseName -AbortOnError -ConnectionTimeout 10 -QueryTimeout 10 -Query "SELECT MAX(StartTime) as LastLoginDate from [cpm].[UserEvents] where EventType = 0"
        $lastLoginDate = $loginQuery.LastLoginDate
	    $querySuccess = $?
	  }
	  $idleTime = $today - $lastLoginDate
  }
  
  Write-Host $site.SiteDefinitionName "..."
  Write-Host "  Id                 :" $site.Id  
  Write-Host "  EnvironemntId      :" $site.EnvironmentId
  Write-Host "  WebServerId        :" $site.WebServerId
  Write-Host "  WebServer          :" $webServer.Address
  Write-Host "  DatabaseServerId   :" $site.DatabaseServerId
  Write-Host "  DatabaseServer     :" $databaseServer.Address
  Write-Host "  DatabaseName       :" $site.DatabaseName
  Write-Host "  Last Login         :" $lastLoginDate
  Write-Host "  Release            :" $site.Release
  Write-Host "  BuildNumber        :" $site.BuildNumber
  Write-Host "  SiteDefinitionName :" $site.SiteDefinitionName
  Write-Host "  SiteDefinitionId   :" $siteDefinition.Id
  Write-Host "  MemberId           :" $siteDefinition.MemberId

  Write-Host "  UserName           :" $member.UserName
  Write-Host "  Days Idle          :" $idleTime.Days
  Write-Host "  Status             :" -nonewline
  
  if ($querySuccess -eq $FALSE)
  {
    $errorCount++
    Write-Host -foregroundcolor red " Error"
  }
  elseif ($idleTime.Days -gt $cutOffDays)
  {
    $idleCount++
    Write-Host -foregroundcolor yellow " Idle"
  }
  else
  {
    Write-Host -foregroundcolor green " Good"
  }
  Write-Host
}

Write-Host ""
$s = [String]::Format("Total {0} sites, {1} idle more than {2} days, ", $siteList.Length, $idleCount, $cutOffDays)
Write-Host $s -nonewline
if ($errorCount -gt 0)
{
  Write-Host -foregroundcolor red $errorCount -nonewline 
}
else
{
  Write-Host $errorCount -nonewline 
}
Write-Host " errors"
Write-Host ""
