# SQL Server

- [Overview](#overview)
- [Normalization](#normalization)
- [Authentication and Authorization](#authentication-and-authorization)
  - [Concepts](#concepts)
  - [Permissions](#permissions)
  - [Ownership chains](#ownership-chains)
- [Special tables](#special-tables)
  - [System tables](#system-tables)
  - [Temporary tables](#temporary-tables)
  - [Temporal tables](#temporal-tables)
- [Datatypes](#datatypes)
  - [`varchar` vs `nvarchar`](#varchar-vs-nvarchar)
- [Indexes](#indexes)
- [Isolation levels](#isolation-levels)
- [Query plans](#query-plans)
  - [Common problems](#common-problems)
- [Query Store](#query-store)
- [Dynamic Management Views (DMV)](#dynamic-management-views-dmv)
- [Performance improvements](#performance-improvements)
  - [Wait statistics](#wait-statistics)
  - [Tune indexes](#tune-indexes)
  - [Resumable index](#resumable-index)
  - [Query hints](#query-hints)
- [Cheatsheets](#cheatsheets)


## Overview

Most content applies to SQL Server only.

Some apply to Azure SQL, as noted.


## Normalization

- **First normal form**
  - A primary key for each table (could be a composite key)
  - No repeating groups (multiple columns for similar data)
- **Second normal form**
  - If a table has a composite key, other attributes must depend on the complete key, not just part of it
- **Third normal form**
  - All nonkey columns are nontransitively dependent on the primary key (a column shouldn't be dependent on another nonkey column)
  - Typically the aim for most OLTP dbs

Considerations:

- A normalized database doesn't always give you the best performance, it requires multiple join operations to get all the necessary data returned in a single query
- Denormalized data can be more efficient, especially for read heavy workloads like a data warehouse. Extra columns offer simpler queries.
  - Data warehouse usually has a star schema or snowflake schema (fact table in the center, which contains mostly numeric values)


## Authentication and Authorization

### Concepts

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


## Special tables

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

### Temporal tables

- To track and analyze the changes to your data
- Recover data from a history table


## Datatypes

### `varchar` vs `nvarchar`

`varchar` is stored as regular 8-bit data (1 byte per character) and `nvarchar` stores data at 2 bytes per character, so usually you should use `nvarchar` for Unicode text


## Indexes

- **Clustered index**
  - Is the underlying table, defines how the rows are sorted
  - A table can have Only one clustered index
    - A table without a clustered index is called a heap, typically used only as staging tables
  - Clustered index key should:
    - As narrow as possible
    - Use columns with unique and distinct values
    - On columns used frequently for sorting
    - Usually include the primary key (but NOT mandatory)
  - Primary key will be clustered by default, if you don't specify another clustered key
  - eg. for an `Orders` table, primary key is `OrderId`, clustered index on `OrderDate`
- **Nonclustered indexes**
  - Separate structures from the data rows
  - Contains the key values
  - Always contains the clustered key
  - Can have multiple nonclustered indexes on a table
  - Can add extra nonkey columns to the leaf level of an index
    - If a nonclustered index doesn't have all the columns to fulfill a query, then a "**Key lookup**" against the clustered index operation happens in an execution plan
- **Columnstore indexes**
  - Intially targeted at data warehouses
    - Best on analytic queries scanning large data sets, such as fact tables
  - Enhance performance for queries involving large aggregation
  - Store each column independently
    - Reduced IO by scanning necessary columns
    - Greater compression due to similar data within a column
  - Batch execution mode: `SELECT SUM(Sales) FROM SalesAmount;`
  - Min. number of rows to bulk insert into a columnstore index: 102,400
  - Clustered
    - Represents the table itself, stored in a special way
    - Include all columns, but NOT sorted
  - Nonclustered
    - Stored independently

![B-tree index](./images/sqlserver_index-b-tree.png)

Considerations:

- Read benefits from indexes more
- Optimize indexes for most frequently run queries
- Choose appropriate data types
- Use *filtered index* in large tables on columns with with low-cardinality values (like a bit flag)
- Create indexes on views, if the view contains aggregations and/or joins


## Isolation levels

- It's a session level setting, there's NO global isolation level
- Use a proper level to balance consistency and concurrency
- Locks could be on different levels:
  - Row
  - Table (if more than 5000 rows need to be locked, escalate to the table level)
  - DB
- "autocommit" is the default, or explicitly use `BEGIN TRANSACTION` and `COMMIT TRANSACTION`

Levels:

- Read uncommitted
  - Max concurrency
  - Read uncommitted data from another transcation
- Read committed (default level)
  - Shared lock released after read
  - If a row is read multiple times in the same transaction, it might get different data (updated by other transactions)
- Repeatable Read
  - Holds "shared lock" on a row, preventing updates
  - Phantom rows: another transaction could still insert a new row with the same ID
- Serializable
  - Holds a "key-range" lock, preventing inserts into the key range
  - Lowest concurrency
- With row-versioning
  - To turn on SNAPSHOT for a DB: `ALTER DATABASE MyDb SET ALLOW_SNAPSHOT_ISOLATION ON`
  - Levels
    - Read Committed Snapshot (RCSI)
      - RCSI is the default, no need to set in the session
      - Transaction always see last committed version at the time when transaction began
      - If the transaction read again, it may get a newly committed value
    - Snapshot
      - Need to be set explicitly in a session: `SET TRANSACTION ISOLATION LEVEL SNAPSHOT`
      - Like RCSI, reader gets old committed data, not blocked
      - Different form RCSI, this gets a static snapshot, used through out the transaction (like "Repeatable Read")

Troubleshooting:

- Use `sys.dm_tran_locks`, joined with `sys.dm_exec_requests`, to find locks held by each session
- Or use Extended Events
  ```sql
  USE MASTER
  GO

  CREATE EVENT SESSION [MySession] ON SERVER
    ADD EVENT sqlserver.blocked_process_report (
      ACTION (...)
    )
    ...
  GO

  ALTER EVENT SESSION [MySession] ON SERVER
    STATE = start;
  GO
  ```


## Query plans

Query processing steps:

1. Check syntax, generate a parse tree of db objects
1. Parse tree -> *Algebrizer* for bindings -> processor tree
    1. Validates columns and object exists, identifies data types
1. Generates *query_hash*, check if a cache exists in the plan cache
    - Different explicit parameter values could cause a different plan
    - If you use a parameter in your query, `OPTION (RECOMPILE)` causes the query compiler to replace the parameter with its value
2. If no cache, *query optimizer* generates several execution plans
3. Plan executed -> results

Query optimizer

- Cost based
- Factors considered when calculating cost:
  - Statistics on the columns
  - Potential indexes
- Complex queries can have thousands of possible execution plans
- Optimizer doesn't evaluate every single one

Three types of plans:

- Estimated plan
  - `SET SHOWPLAN_ALL ON`
  - Query not executed
  - Saved in plan cache
- Actual plan
  - `SET STATISTICS PROFILE ON`
  - Includes runtime statistics
- Live Query Statistics
  - Animated execution progress

### Common problems

- Hardware constraints
- Suboptimal query constructs
- SARGability
  - Able to use *SEEK* operation on index, instead of scanning the entire index or table
  - Wildcard on the left: `LIKE %word`, make the query non-SARGable
- Missing indexes
  - recommendations in `sys.dm_db_missing_index_details`
- Missing and out-of-date statistics
- Poor optimizer choices
- Parameter sniffing
  - When there's data skew, query performance could vary widely
  - Possible solution: Use hint `OPTION (RECOMPILE)` to force query recompile


## Query Store

Three stores:

- Plan store
- Runtime stats store
- Wait stats store

Need to enable in SQL Server:

```sql
ALTER DATABASE <database_name> SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE);
```

*Enabled by default in Azure SQL DB*

![Query Store](./images/sqlserver_query-store.png)

Built-in views:

- Regressed Queries
- Overall Resource Consumption
- Top Resource Consumption Queries
- Queries with Forced Plans
- Queries with High Variation
- Query Wait Statistics
- Tracked Queries

Automatic plan correction:

- `sys.dm_db_tuning_recommendations`: recommendations about query plan regressions
  - If Query Store is enabled, recommendations are always enabled
- Optionally enable `AUTOMATIC_TUNING`
  - Enabled by default for Azure SQL DB

![Query store storage](./images/sqlserver_query-store-data.png)

Query Store data are written to disk asynchronously

Init size: 100MB, max: 2GB ?


## Dynamic Management Views (DMV)

- There are DMVs and DMFs, most people use the acronym DMV for both
- Hundreds of objects
- Contain system information, to monitor the health of a server instance, diagnose problems, and tune performance
- All prefixed with `sys.dm_*`
- Three categories:
  - db-related
  - query execution related
  - transaction related

Two levels:

- **Server scoped objects** – require `VIEW SERVER STATE` permission on the server
- **Database scoped objects** – require the `VIEW DATABASE STATE` permission within the database

Examples:

- Execution & Query stats (Performance)
  - `sys.dm_exec_query_stats` - query exec time, CPU, reads, ect, contains `sql_handle` and `plan_handle`
  - `sys.dm_exec_query_plan(plan_handle)` - *a DMF*, exec plan XML
  - `sys.dm_exec_query_plan_stats` - Seems same as above ?
  - `sys.dm_exec_sql_text(sql_handle)` - get the text of a SQL batch for a specific sql handle
  - ...
  - `sys.dm_exec_sessions` - user and system sessions (running or sleeping)
  - `sys.dm_exec_requests` - details about each request currently executing, identify long running
  - ...
- Index & stats
  - `sys.dm_db_index_usage_stats` - How often indexes are read/updated
  - `sys.dm_db_missing_index_details` - Missing index suggestions
  - `sys.dm_db_index_physical_stats()` - Fragmentation, page count
  - `sys.dm_db_stats_properties` - Histogram + stats details
- Waits
  - `sys.dm_os_wait_stats` - aggregated data since last restart
  - `sys.dm_os_waiting_tasks` - current waiting tasks
  - `sys.dm_exec_requests` - active queries (including wait type/time as well)
- Locking & Blocking
  - `sys.dm_tran_locks` - current locks, including `session_id`
  - `sys.dm_os_waiting_tasks` - current waiting tasks, including `blocking_session_id`
  - `sys.dm_exec_sessions / requests` - identify blockers
- Memory & caching
  - `sys.dm_os_sys_memory` - OS memory info
  - `sys.dm_exec_cached_plans` - cached plan, size and use counts etc
- I/O & Storage
  - `sys.dm_io_virtual_file_stats()` - I/O stats for database files
  - `sys.dm_db_file_space_usage` - db file space usage
- Resource usage
  - `sys.resource_stats` - in `master`, historical CPU/storage usage data for an Azure SQL Database, has db name and start_time
  - `sys.server_resource_stats` (Azure SQL MI)
  - `sys.dm_db_resource_stats` - (SQL DB) for each DB, one row every 15 seconds, only data for last hour
  - ...
  - `sys.dm_user_db_resource_governance` (Azure SQL DB)
  - `sys.dm_instance_resource_governance` (Azure SQL MI)
- Misc
  - `sys.dm_pdw_nodes_*` - for Azure Synapse Analytics and Analytics Platform System (PDW)


## Performance improvements

### Wait statistics

Three types:

- **Resource waits**
  - Locks, latches, disk I/O
- **Queue waits**
  - a thread waiting for work to be assigned
  - Examples: deadlock monitoring, deleted record cleanup
- **External waits**
  - Examples: getting results from linked server query, return results to client

Stats:

- `sys.dm_exec_session_wait_stats`: active waiting sessions
- `sys.dm_os_wait_stats` wait history (`sys.dm_db_wait_stats` fro Azure SQL DB)
- Query Store also tracks some waits data (not as granular as DMV)

Common waits:

- `RESOURCE_SEMAPHORE`: wait on memory, could indicate long query runtimes (out-of-date stats, missing indexes), or high query concurrency
- `SOS_SCHEDULER_YIELD`: high CPU utilization, suggesting high number of large scans, missing indexes
- `CXPACKET`: improper config or high CPU utilization. To resolve, lower MAXDOP, and increase the cost threshold for parallelism
- `LCK_M_X`: *a lock*, Blocking problem. Could be resolved by changing to `READ COMMITTED SNAPSHOT` isolation level, optimizing indexes, improving transaction management within T-SQL code
- `PAGEIOLATCH_SH`: *a latch*, query scans excessive amounts of data, indicating bad indexes. If `waiting_tasks_count` is low, but `wait_time_ms` is high, it suggests storage performance problems
- `PAGEIOLATCH_UP`: *a latch*, TempDB contention on Page Free Space (PFS) data pages. Best practice: use one file per CPU core for TempDB, the files should have the same size and outgrowth settings

### Tune indexes

- Update operations that do lookups can benefit from extra indexes or columns added to an existing index
- Evaluate existing index usage using `sys.dm_db_index_operational_stats` and `sys.dm_db_index_usage_stats`
- Eliminate unused and duplicate indexes
  - For monthly/quarterly/yearly operations, create indexes just before the operations
- Review and evaluate expensive queries from Query Store, Extended Events capture, manually craft indexes to better serve those
- Test in nonprod environment first
- In an index, columns should be ordered according to selectivity

### Resumable index

You can pause and then restart index building process

```sql
-- Creates a nonclustered index for the Customer table
CREATE INDEX IX_Customer_PersonID_ModifiedDate
    ON Sales.Customer (PersonID, StoreID, TerritoryID, AccountNumber, ModifiedDate)
WITH (RESUMABLE=ON, ONLINE=ON)
GO

ALTER INDEX IX_Customer_PersonID_ModifiedDate ON Sales.Customer PAUSE
GO
```

### Query hints

Examples:

- `FAST <int>`: retrieve first <int> number of rows while continueing query execution
- `OPTIMIZE FOR`
- `USE PLAN` - use a plan specified by the `xml_plan` attribute
- `RECOMPILE` - create a new, temporary plan for the query, and discards it immediately after the query is executed
- `{ LOOP | MERGE | HASH } JOIN` - specifies method for all join operations in the query
- `MAXDOP <int>` - overrides `sp_configure`, also Resource Governor

Notes:

If you can't modify query text, you can set hints for a query in Query Store:

`EXEC sys.sp_query_store_set_hints @query_id= 42, @query_hints = N'OPTION(RECOMPILE, MAXDOP 1)'`


## Cheatsheets

- Run with Docker

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

  # run in the container
  /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "myPassword"
  ```

- Create a database and a table

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
  ```

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
