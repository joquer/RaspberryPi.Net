USE master;
GO
SET NOCOUNT ON
DECLARE @spid_str_kill varchar(1000)	-- Stores query to Kill SQL Server Process by Ids
DECLARE @ConnKilled smallint			-- Stores the count of connections killed
DECLARE @Database_id smallint			-- Stores database identification (ID) number
SET @ConnKilled=0
SET @spid_str_kill = ''
SET @Database_id = db_id('$(dbname)')
DECLARE @retvalue int, @data_dir varchar(500)

PRINT 'Checking connections for DB $(dbname)'
-- Checking Whether '$(dbname)' exists or not
IF EXISTS (SELECT 1 FROM sys.databases WHERE [name] = '$(dbname)')
	BEGIN
		--- Checking Whether '$(dbname)' is a system DB or not
		IF (@Database_id < 4)
			BEGIN
				PRINT 'Connections to system databases cannot be killed'
				RETURN
			END
		ELSE
			BEGIN
				-- Checking for connection related to '$(dbname)'
				SELECT @spid_str_kill=coalesce(@spid_str_kill,',' )+'kill '+convert(varchar, spid)+ '; ' FROM master.sys.sysprocesses WHERE dbid=@Database_id
					-- to avoid system processes
					AND status <> 'background' 
					-- to get the user process
					AND status IN ('runnable','sleeping') 
					-- to avoid the current spid
					AND spid <> @@spid;
				-- If connection exists for the '$(dbname)', Kill all the connection before dropping it.
				IF LEN(@spid_str_kill) > 0
					BEGIN
						EXEC(@spid_str_kill)
						SELECT @ConnKilled = COUNT(1) FROM master.sys.sysprocesses WHERE dbid=@Database_id;
						PRINT  CONVERT(VARCHAR(10), @ConnKilled) + ' Connection(s) killed for DB $(dbname)'
					END
				ELSE
					BEGIN
						PRINT 'No connections found for DB $(dbname)'
					END
			END
		-- Set '$(dbname)' to single user before dropping the DB
		ALTER DATABASE [$(dbname)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		PRINT 'Dropping $(dbname)'
		DROP DATABASE [$(dbname)];
	END

