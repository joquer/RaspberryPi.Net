#Requires -Version3.0
param (
  $FromBranch,
  $ToBranch,
  [switch]$Quiet = $False
)

Write-Host
Write-Host "Merging changes from $FromBranch to $ToBranch"
Write-Host

git fetch

$branches = git branch --remote | ? { $_.Trim() -eq "origin/$FromBranch" }
if ($branches.Count -eq 0)
{
  Write-Host ("    ERROR:  Branch {0} not found." -f $FromBranch)
  exit 1
}

$branches = git branch --remote | ? { $_.Trim() -eq "origin/$ToBranch" }
if ($branches.Count -eq 0)
{
  Write-Host ("    ERROR:  Branch {0} not found." -f $ToBranch)
  exit 1
}

$quietOption = ""
if ($quiet -eq $True)
{
  $quietOption = "--quiet"
}

git checkout $quietOption -f $ToBranch
git pull $quietOption origin $FromBranch

if ($LastExitCode -ne 0)
{
  git merge $quietOption --abort
  Write-Host "    ERROR:  Merge failed"
  exit 1
}

git push $quietOption origin $ToBranch
Write-Host "    Merge Successful"
