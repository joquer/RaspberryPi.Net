param (
  $CutOffWeeks = 6
)

$currentDate = Get-Date
$cutOffDate = $currentDate.AddDays(-($cutOffWeeks - 1) * 7)

Write-Host
Write-Host "Branches that will be deleted on" $cutOffDate
Write-Host "Commit a change or move out of idle to preserve"
Write-Host

$branchList = git branch --remote | ? { $_.Contains("HEAD") -eq $FALSE }
$branchList = $branchList | ? { $_.Contains("master") -eq $FALSE }
$branchList = $branchList | ? { $_.Contains("develop") -eq $FALSE }
$branchList = $branchList | ? { $_.Contains("release/next-release") -eq $FALSE }

[int]$count = 0
foreach ($branch in ($branchList | ? { $_.Contains("origin/idle") }))
{
    $shortBranchName = $branch.Replace("origin/", "")
    $lastCommitDate = git log "-1 $branch ^develop --date=short --format=%cd --no-merges"
	  if ($lastCommitDate -lt $cutOffDate)
    {
	     Write-Host "  " $lastCommitDate $shortBranchName
       $count++
    }
}

if ($count -eq 0)
{
  Write-Host "    No idle branches"
}

$cutOffDate = $currentDate.AddDays(-($cutOffWeeks -2) * 7)

Write-Host
Write-Host "Moving branches older than" $cutOffDate "to idle"
Write-Host

[int]$count = 0
foreach ($branch in ($branchList | ? { $_.Contains("origin/feature") }))
{
    $shortBranchName = $branch.Replace("origin/", "")
    $lastCommitDate = git log "-1 $branch ^develop --date=short --format=%cd --no-merges"
    if ($lastCommitDate -lt $cutOffDate)
    {
      Write-Host ("  {0} {1}" -f $lastCommitDate, $shortBranchName)
      git push --quiet origin $shortBranchName:idle/$shortBranchName
      git push --quiet origin :$shortBranchName
      $count++
    }
}

if ($count -eq 0)
{
  Write-Host "    No idle branches"
}

$cutOffDate = $currentDate.AddDays(-$cutOffWeeks * 7)

Write-Host
Write-Host "Deleting idle branches older than" $cutOffDate
Write-Host

[int]$count = 0
foreach ($branch in ($branchList | ? { $_.Contains("origin/idle") }))
{
    $shortBranchName = $branch.Replace("origin/", "")
    $lastCommitDate = git log "-1 $branch ^develop --date=short --format=%cd --no-merges"
    if ($lastCommitDate -lt $cutOffDate)
    {
	    Write-Host ("  {0} {1}" -f $lastCommitDate, $shortBranchName)
      git push --quiet origin :$shortBranchName
      $count++
    }
}

if ($count -eq 0)
{
  Write-Host "    No stale branches to delete"
}
Write-Host
