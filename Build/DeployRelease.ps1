#Requires -Version 3.0
param(
    [string]$release = $Null,
    [string]$buildType = "Dev",
    [int]$buildNumber,
    [string]$databaseServerAddress = "cpm-dev-db01.devid.local",
    [string]$databaseName,
    [string]$webServerAddress = "cpm-dev-app01.devid.local",
    [string]$yggdrasilServiceUrl,
    [string]$siteManagerUrl,
    [string]$productAbbrev = "CMGA",
	[string]$siteName = $Env.SITE_NAME)

$root = Split-Path $MyInvocation.MyCommand.Path

if ($release -eq $Null -or $release -eq "")
{
  Write-Host "ERROR:  The Release Label is required, please provide a value for the -Release parameter"
  exit 1
}

if ($buildType -eq "QA")
{
    $yggdrasilEnvironment = "QA"
}
else
{
    $yggdrasilEnvironment = "Development"
}

$siteName = $siteName.Replace(".", "_")

$env:YggdrasilServiceUrl = $yggdrasilServiceUrl
$env:SiteManagerServiceUrl = $siteManagerUrl

. (Join-Path $root "LoadSiteManagerAssemblies.ps1")

Write-Host @"
=== Parameters
Release             : $release
Build Number        : $buildNumber
Site Name           : $siteName
Database Name       : $databaseName
Database Server     : $databaseServerAddress
webServerAddress    : $webServerAddress
yggdrasilServiceUrl : $yggdrasilServiceUrl
siteManagerUrl      : $siteManagerUrl
Environment         : $yggdrasilEnvironment
Product Abbrev      : $productAbbrev
===
"@
 

# Get the Environment
$environment = Get-YggdrasilEnvironment | ? { $_.Name -eq $yggdrasilEnvironment }
if ($environment -eq $Null)
{
  Write-Host ("Environment Not Found: {0}" -f $yggdrasilEnvironment )
  exit 1
}
$environmentId = $environment.Id
Write-Host "Environment Id      : $environmentId"

# Get the Product
$product = Get-YggdrasilProduct | ? { $_.Abbreviation -eq $productAbbrev }
if ($product -eq $Null)
{
  Write-Host -nonewline -foregroundcolor red "Error:  "
  Write-Host ("Product Not Found: {0}" -f $productAbbrev)
  exit 1
}
Write-Host "Product Id          :" $product.Id

# Get the Server Types
$allServerTypes = Get-YggdrasilServerType
$databaseServerType = $allServerTypes | Where { $_.Name -eq "Database" }
$webServerType = $allServerTypes | Where { $_.Name -eq "Web" }

if ($databaseServerType  -eq $Null -or $webServerType -eq $Null)
{
  Write-Host -nonewline -foregroundcolor red "Error:  "
  Write-Host "Server Types Not Found"
  exit 1
}

$databaseServer = Get-YggdrasilServer -ServerTypeId $databaseServerType.Id -Address $databaseServerAddress
if ($databaseServer -eq $Null )
{
  Write-Host -NoNewline -ForegroundColor red "ERROR: "
  Write-Host ("Database Server {0} does not exist." -f $databaseServerAddress)
  exit 1
}

Write-Host ("Database Server Id  : {0}" -f $databaseServer.Id)
        
# Conditionally add Web Server
$webServer = Get-YggdrasilServer -ServerTypeId $webServerType.Id -Address $webServerAddress
if ($webServer -eq $Null)
{
  Write-Host -NoNewline -ForegroundColor red "ERROR: "
  Write-Host ("Web Server {0} does not exist." -f $webServerAddress)
  exit 1
}

Write-Host "webServer Id        :" $webServer.Id

$member = Get-YggdrasilMember -Name "CPM_Auto_Deploy_Member"
Write-Host "member Name         :" $member.Name
Write-Host "member Id           :" $member.Id
Write-Host "member UserName     :" $member.UserName

# Configure Login and User for the member database using the member UserName
[string]$userName = $member.UserName
if ($productAbbrev -eq "CMGA")
{
  $sqlVars = "MemberUserName=$userName", "MemberDatabaseName=$databaseName"
  $sqlPath = Join-Path $root "SQL\ConfigureApplicationDatabase.sql"
  Invoke-Sqlcmd -Verbose -ServerInstance $databaseServerAddress -AbortOnError -ConnectionTimeout 2 -QueryTimeout 10 -InputFile $sqlPath -Variable $sqlVars
}

$siteDefinition = Get-YggdrasilSiteDefinition -Name $siteName | ? { $_.Name -eq $siteName }
if ($siteDefinition -eq $Null)
{
  New-YggdrasilSiteDefinition -Name $siteName -ProductId $product.Id -MemberId $member.Id -WebApplicationName $siteName | Add-YggdrasilSiteDefinition 
  $siteDefinition = Get-YggdrasilSiteDefinition -Name $siteName | ? { $_.Name -eq $siteName }
}

Write-Host "siteDefinition Id :" $siteDefinition.Id

$site = Get-YggdrasilSite -SiteDefinitionName $siteName
if ($site -ne $Null)
{
  $siteId = $site.Id
  Write-Host "  Site Exists UnPublishing ($siteId)..."
  UnPublish-Site -SiteId $siteId
}

# Deploy the site

Publish-Site `
    -EnvironmentId $environmentId `
    -ProductId $product.Id `
    -SiteDefinitionId $siteDefinition.Id `
    -Release $release `
    -BuildNumber $buildNumber `
    -WebServerId $webServer.Id `
    -DatabaseServerId $databaseServer.Id `
    -DatabaseName $databaseName 

if ($productAbbrev -eq "CPM" -or $productAbbrev -eq "CMGA")
{
	# the Last Login date for all users in cpm.Users is used to determine if a site is idle.
	# This query sets a last login date to today so that the site will not be deleted during
	# the next Clean Sites run.
	$query = "INSERT INTO [cpm].[UserEvents] (UserKey, StartTime, EndTime, EventType) values ((select MIN(UserKey) from cpm.Users), GETDATE(), GETDATE(), 0)"	
	Invoke-Sqlcmd -AbortOnError -ConnectionTimeout 2 -ServerInstance $databaseServerAddress -Database $databaseName -Query $query
}

Write-Host "Deploy successful. Site URL: https://$webServerAddress/$siteName" 
