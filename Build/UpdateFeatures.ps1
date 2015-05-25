
$root = Split-Path $MyInvocation.MyCommand.Path

$branchList = git branch --remote | Select-String "origin/feature"

Write-Host "Updating the following branches..."
Write-Host
foreach($branch in $branchList)
{
  Write-Host ("    {0}" -f $branch.Line)
}

Write-Host
Write-Host "Updating..."

[bool]$mergeError = $False 
$pullBranch = Resolve-Path (Join-Path $root ".\PullBranch.ps1")
foreach($branch in $branchList)
{
  $branch = $branch.Line.Trim()
  $shortBranchName = $branch.Replace("origin/", "")
  if ($shortBranchName.Contains("XPD") -eq $False)
  {
    & $pullBranch -FromBranch develop -ToBranch $shortBranchName -Quiet
    if ($LASTEXITCODE -ne 0)
    {
      $mergeError = $True
    }
  }
}

if ($mergeError -eq $True)
{
  exit 1
}

