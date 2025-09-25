# Oracle DBs

- [Concepts](#concepts)
  - [`dual` table](#dual-table)
  - [Built-in users](#built-in-users)


## Concepts

```
[CDB (Container Database)]
  ├── CDB$ROOT         (Core Oracle system data, common users)
  ├── PDB$SEED         (Template used to create new PDBs)
  ├── PDB1             (Your first user-created database)
  └── PDB2             (Another user-created database)
```

- Container Database (CDB)
  - Manages shared resources
  - ONLY ONE CDB per Oracle instance
- Pluggable Databases (PDBs)
  - Each PDB has its own schema, users, and data
  - Could be unplugged and plugged into other CDBs
  - A PDB is also called a "container"


```sql
-- Connect as SYSDBA
sqlplus sys@CDB1 as sysdba

-- Show pluggable databases
SHOW PDBS;

-- Switch to a specific PDB
ALTER SESSION SET CONTAINER = PDB1;

-- Confirm
SELECT * FROM v$database;

-- List tables in the current PDB
-- Your own tables
SELECT table_name FROM user_tables;
-- All accessible tables
SELECT owner, table_name FROM all_tables;
-- All tables in PDB (DBA only)
SELECT owner, table_name FROM dba_tables;
```

Create a user

```sql
-- Switch to root container
ALTER SESSION SET container = CDB$ROOT;

-- Create a new user
CREATE USER c##datadog IDENTIFIED BY &password CONTAINER = ALL;
ALTER USER c##datadog SET CONTAINER_DATA=ALL CONTAINER=CURRENT;

-- Find service name
SELECT value FROM v$parameter WHERE name='service_names';

-- To connect using the user/pass
-- sqlplus c##datadog/OraclePass@//localhost:1521/XE
```

### `dual` table

- Special built-in table
- Return values without querying real tables
- Use case `SELECT expression FROM dual;`

```sql
-- valid in MySQL, but not in Oracle
SELECT 1;

-- `FROM` is required in Oracle
SELECT 1 FROM dual;

-- Example: get current user and date
SELECT USER, SYSDATE FROM dual;
```

### Built-in users

- SYS
  - The most powerful user
  - Owns the base tables and views for the database's metadata
  - Always connects as SYSDBA