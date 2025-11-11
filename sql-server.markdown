# SQL Server

- [Overview](#overview)
- [Run with Docker](#run-with-docker)
- [Concepts](#concepts)
- [Create and query data](#create-and-query-data)
  - [Temporary tables](#temporary-tables)
- [Datatypes](#datatypes)
  - [`varchar` vs `nvarchar`](#varchar-vs-nvarchar)
- [Authorization](#authorization)
  - [Permissions](#permissions)
  - [Ownership chains](#ownership-chains)
  - [System tables](#system-tables)
- [Cheatsheets](#cheatsheets)


## Overview

Most content applies to SQL Server.

Some apply to Azure SQL, as noted.


## Run with Docker

```sh
docker run \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=myPassword" \
  -p 1433:1433 \
  --name sql1 \
  -h sql1 \
  -d mcr.microsoft.com/mssql/server:2019-latest
```

Connect to SQL Server

```sh
docker exec -it sql1 "bash"

/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "myPassword"
```


## Concepts

- **Security principals**:
  - Entities with certain permissions
  - At either server level or database level
  - Can be individuals or collections
  - A role is like a group, is also a security principal
  - There are several sets in SQL Server, some have fixed membership, some sets have a membership controlled by the SQL Server administrators
- **Securables scopes**:
    - Server
    - Database
    - Schema: you can assign permissions to a role at this level
- **Schema**
  - A schema is like a folder inside a database that holds tables, views, etc.
  - Helps with organization, permissions, and naming separation
  - Every user has a default schema (if no, then it's `dbo`)
    - `dbo` stands for "database owner"
  - If you don't specify schema, like `SELECT name FROM customers`, it checks the user default schema, then `dbo`
  - Best practices is to always specify a schema
- **Logins**
  - At server instance level
  - Credentials stored in the `master` db
  - Should be linked to by user accounts in one or more DBs
  - Logins are for authentication, the mapped users are for authorization in each DB
  ```sql
  USE [master]
  GO

  -- create login in master db
  CREATE LOGIN demo WITH PASSWORD = 'Pa55.w.rd'
  GO

  USE [MyDBName]
  GO

  -- create a linked user in another db
  CREATE USER demo FROM LOGIN demo
  GO
  ```
- **Contained users**
  - Database level
  - Not linked to a login
  - Could be SQL auth or Windows/Entra auth
  - DB must be configured for partial containment (default in Azure SQL DB, optional in SQL Server)
  ```sql
  -- in a user db context
  CREATE USER [dba@contoso.com] FROM EXTERNAL PROVIDER;
  GO
  ```
- **Roles**
  - Effective security groups
  - Custom roles can be created at the server or db level
    - Server roles can't be granted access to db object directly
    - Server roles NOT available in Azure SQL DB
    - Schema scoped permissions can be granted to a role

  ```sql
  CREATE USER [DP300User1] WITH PASSWORD = 'Pa55.w.rd'
  GO
  CREATE ROLE [SalesReader]
  GO
  ALTER ROLE [SalesReader] ADD MEMBER [DP300User1]
  GO
  GRANT SELECT, EXECUTE ON SCHEMA::Sales TO [SalesReader]
  GO
  ```
  - Application roles
    - There's a preconfigured password
    - User activate the role with the password, then the role permissions are applied to the user, until the role is deactivated
  - Built-in db roles (for each db)
    - All configured with `db_`
    - eg. `db_owner`, `db_datareader`, `db_accessadmin` (can create new users), `db_securityadmin` (can grant permissions)
    - `db_denydatawriter`: prevent from writing data, when users have been granted rights via other roles or directly
    - All users with  adb are automatically members of the `public` role, which has no permissions
    - `db_owner` users can always see all data in a db, applications can use `Always Encrypted` to protect data from privileged users
    - Azure SQL DB nuances
      - `master` db is virtual
      - Sever admin has `sysadmin` rights, you can create more limited admins
      - Two db level roles, only exist in the virtual `master` db: `loginmanager`, `dbmanager`
  - Fixed server-level roles
    - Can be assigned to server-level principals (SQL Server logins, Windows accounts, Windows groups)
    - Permissions are fixed, except the `public` role
    - eg. `sysadmin`, `serveradmin`, `securityadmin`, `dbcreator`, `public` etc
    - Server-level roles in Azure SQL DB:
      - `MS_DatabaseConnector`
      - `MS_DatabaseManager`
      - `MS_DefinitionReader`
      - `MS_LoginManager`
      - `MS_SecurityDefinitionReader`
      - `MS_ServerStateReader`
      - `MS_ServerStateManager`


## Create and query data

```sql
CREATE DATABASE TestDB
SELECT Name from sys.Databases

GO  --need this to actually run queries above

USE TestDB
CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)
INSERT INTO Inventory VALUES (1, 'banana', 150), (2, 'orange', 154);
GO

SELECT * FROM Inventory WHERE quantity > 152;
GO

QUIT
```

### Temporary tables

- Temporary table name starts with `#`, can be created using `SELECT INTO` or normal `CREATE TABLE`
- They exists in system database `tempdb`
- Temporary tables are only accessible within the session that created them
- To make a temporary table accessible across connections, prefix table name with `##`

```sql
USE TestDB
SELECT * INTO #mytemptable FROM Inventory WHERE id = 1;
GO

SELECT * FROM #mytemptable
```

## Datatypes

### `varchar` vs `nvarchar`

`varchar` is stored as regular 8-bit data (1 byte per character) and `nvarchar` stores data at 2 bytes per character, so usually you should use `nvarchar` for Unicode text


## Authorization

### Permissions

- Four basic operation permissions: `SELECT`, `INSERT`, `UPDATE`, and `DELETE`
  - Other table/view permissions: `CONTROL`, `REFERENCES`, `TAKE OWNERSHIP`, `VIEW CHANGE TRACKING`, `VIEW DEFINITION`
  - Function/stored procedure permissions: `ALTER`, `CONTROL`, `EXECUTE`, `VIEW CHANGE TRACKING`, `VIEW DEFINITION`
- Perimssions can be granted, revoked, or denied
  - On tables and views
  - `DENY` supersedes over `GRANT`
  - Can additionally restrict the columns
  - SQL Server and Azure SQL DB also include row-level security
- You can use `EXECUTE AS USER = <user_name>` to change user context

### Ownership chains

- When a funcion or stored procedure executes, it inherits the permissions of the owner.
- Example:
  - The owner of `SP_DEMO` has access to `SELECT` on `[Sales].[Orders]`
  - User `user001` does not have access to `[Sales].[Orders]`, but can `EXECUTE` `SP_DEMO`
  - Then `user001` can't execute `SELECT` on the table, but can run the stored procedure
- Dynamic SQL in a stored procedure is executed outside the context of the calling procedure, DON'T inherit permissions of the procedure owner. The calling user's permissions apply.

### System tables

- `sys.database_principals` contains both individual users and roles, each has a principal_id
- `sys.database_role_members` contains members of each role, eg. `dbo` is a member of `db_owner`
- users: `dbo`, `guest`, `sys`, ...
- roles: `db_owner`, `db_accessadmin`, `db_datareader`, ...
- Query users of each role

  ```sql
  -- Query users in a particular role
  SELECT dp.name, dp.type_desc, dprole.name
  FROM
      sys.database_role_members drm
  JOIN
      sys.database_principals dp ON drm.member_principal_id = dp.principal_id
  JOIN
      sys.database_principals dprole ON drm.role_principal_id = dprole.principal_id
  ```


## Cheatsheets

- A join query

  ```sql
  SELECT p.ProductID, p.Name AS ProductName,
          c.Name AS Category, p.ListPrice
  FROM SalesLT.Product AS p
  JOIN [SalesLT].[ProductCategory] AS c
      ON p.ProductCategoryID = c.ProductCategoryID;
  ```

- Show client name and IP

  ```sql
  SELECT  hostname,
          net_library,
          net_address,
          client_net_address
  FROM    sys.sysprocesses AS S
  INNER JOIN    sys.dm_exec_connections AS decc ON S.spid = decc.session_id

  -- hostname      net_library    net_address     client_net_address
  -- vm-demo       TCP/IP         FCAC0BDC7F1C    10.0.0.8
  -- GARY-WIN10    TCP/IP         87C81F2C585D    218.101.119.105


  -- for current client only
  SELECT  hostname,
        net_library,
        net_address,
        client_net_address
  FROM    sys.sysprocesses AS S
  INNER JOIN    sys.dm_exec_connections AS decc ON S.spid = decc.session_id
  where spid = @@SPID
  ```


- Loop through a list of tables/dbs to get some stats

  ```sql
  -- get all table names
  DROP TABLE IF EXISTS #tablenames
  CREATE TABLE #tablenames (name NVARCHAR(50));
  INSERT INTO #tablenames VALUES ('Table1'), ('Table2')

  -- create a stats table
  DROP TABLE IF EXISTS #tablestats
  CREATE TABLE #tablestats (
    name NVARCHAR(50),
    mycount INT,
  );

  DECLARE @tblname VARCHAR(50)
  DECLARE @sql NVARCHAR(300)
  -- use a cursor for looping
  DECLARE db_cursor CURSOR FOR
    SELECT name FROM #tablenames

  OPEN db_cursor
    FETCH NEXT FROM db_cursor INTO @tblname -- get value into a variable
    WHILE @@FETCH_STATUS = 0
      BEGIN
          PRINT @tblname

          SET @sql = 'INSERT INTO #tablestats VALUES (''' + @tblname + ''', (SELECT COUNT(id) FROM TestDB.dbo.' + @tblname + ')  )'
          EXEC(@sql)

          FETCH NEXT FROM db_cursor INTO @tblname
      END
  CLOSE db_cursor
  DEALLOCATE db_cursor

  SELECT * FROM #tablestats
  ```
