USE master;
GO
SET NOCOUNT ON
BACKUP DATABASE [$(dbname)] TO  DISK = N'$(dbBackupPath)' WITH FORMAT, INIT, NAME=N'$(dbname)-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
