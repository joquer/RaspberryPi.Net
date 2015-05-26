param (
  $Target = "Compile",
  $BuildFile = "CI.build",
  [switch]$Restore
)

dnu restore
# .\.nuget\nuget.exe install .nuget\packages.config -OutputDirectory packages

if ($Restore -eq $True)
{
  exit 0
}

packages\nant.0.92.2\nant\bin\nant.exe -buildfile:Build\$buildFile $target
