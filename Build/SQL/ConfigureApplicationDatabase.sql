-- This script is derived from \schema\Configuration\ConfigureApplicationDatabase.sql
--
-- Purpose - Automatically create login and user account as required.

PRINT 'Member Database Name: $(MemberDatabaseName)';
PRINT 'Member User Name: $(MemberUserName)';

Set NoCount On

        USE [master];
        IF NOT EXISTS (SELECT * FROM sys.server_principals SP WHERE SP.TYPE in ('U','G') AND name='$(MemberUserName)')
        Begin
            PRINT 'Creating Login $(MemberUserName)'
            CREATE LOGIN [$(MemberUserName)] FROM WINDOWS WITH DEFAULT_DATABASE=[$(MemberDatabaseName)]
        End


PRINT 'Creating and configuring user $(MemberUserName) on database $(MemberDatabaseName)';
        USE [$(MemberDatabaseName)];
        IF EXISTS (SELECT * FROM sys.database_principals DP WHERE DP.TYPE in ('U','G') AND name='$(MemberUserName)')
        Begin
            PRINT '  Dropping User $(MemberUserName)';
            DROP USER [$(MemberUserName)]
        End
          
        PRINT '  Creating User $(MemberUserName)';

        CREATE USER [$(MemberUserName)] FOR LOGIN [$(MemberUserName)];
        EXEC sp_addrolemember 'db_datareader', [$(MemberUserName)];
        EXEC sp_addrolemember 'db_datawriter', [$(MemberUserName)];
        GRANT EXECUTE TO [$(MemberUserName)];
