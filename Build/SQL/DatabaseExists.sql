
if not exists(select [name] from master.dbo.sysdatabases where name = '$(dbname)')
BEGIN
  SELECT 0 as FileExists
END
ELSE
BEGIN
  SELECT 1 as FileExists
END

