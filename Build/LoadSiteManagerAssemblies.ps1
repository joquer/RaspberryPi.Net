#Requires -Version 3.0

$root = Split-Path $MyInvocation.MyCommand.Path
$solutionDir = Resolve-Path (Join-Path $root "..")
$packageConfigPath = (Join-Path $solutionDir ".nuget\packages.config")
$packageConfig = [xml](Get-Content $packageConfigPath)

function FindPackage($packageName)
{
  $version = $packageConfig.packages.package | ? { $_.id -eq $packageName } | Select-Object version
  "packages\{0}.{1}" -f $packageName, $version.version
}

$packagepath = Join-Path $solutiondir (FindPackage("Crimson.Yggdrasil.CLI"))
$packagepath = Join-Path $packagepath "tools\Crimson.Yggdrasil.CLI.dll"
if ((Test-Path $packagepath) -eq $false)
{
  throw "Crimson.Yggdrasil.CLI nuget package not found"  
}
import-module $packagepath -DisableNameChecking

$packagepath = Join-Path $solutiondir (FindPackage("SiteManager.CLI"))
$packagepath = Join-Path $packagepath "tools\SiteManager.CLI.dll"
if ((Test-Path $packagePath) -eq $False)
{
  throw "SiteManager.CLI nuget package not found"  
}
Import-Module $packagePath -DisableNameChecking

