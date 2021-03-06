# SQL Server

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


## Cheatsheets

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