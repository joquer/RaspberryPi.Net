param (
  $branchName
)

$list = git branch -r | ForEach { $_.Replace("origin/", "") } | Select-String $branchName
if ($list.Count -gt 0)
{
  Write-Host "Valid"
}
else
{
  Write-Host "Unknown"
}
