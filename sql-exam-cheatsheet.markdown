- [Migration](#migration)
- [Performance](#performance)
  - [Storage](#storage)
  - [Indexes](#indexes)
  - [Query](#query)
  - [SQL Server](#sql-server)
  - [SQL MI](#sql-mi)
  - [SQL DB](#sql-db)
  - [Settings](#settings)
- [Security](#security)
- [HA/DR](#hadr)
  - [PaaS](#paas)
- [Backup/restore](#backuprestore)
- [Maintainance](#maintainance)

## Migration

- On-prem DB with TDE to SQL MI, where to upload TDE cert to ?
  - The MI itself, NOT a key vault

- Online migration using Azure Database Migration Service
  - SQL MI and SQL in VM
  - NOT SQL DB

- Preferred online strategy for SQL MI
  - DMS
  - MI Link
  - NOT LRS

## Performance

### Storage

- Shrink files
  - DBCC SHRINKDATABASE - shrink the size of data and log files for an entire db
  - DBCC SHRINKFILE - shrink the size of a paticular file
  - sp_clean_db_free_space - clean up space within files, not reduce file size
  - sp_clean_db_file_free_space - similar, on specific file

- Disk strping steps:
  - A storage pool
  - A virtual disk using stripe layout
  - A volume

- Azure SQL DB max log size ?
  - 30% of max data size

- Storage for SQL tiers:
  - General Purpose: remote storage, premium SSD
  - Business Critical: local SSD
  - Hyperscale: Page server

### Indexes

- Nonclustered indexes
  - Enables efficient lookups, reduces full table scans

### Query

- See query parameter values:
  - Enable Lightweight_Query_Profiling in db
  - Enable Last_Query_Plan_Stats in db

- Lightweight profiling
  - Can be enabled at query level using query hint `OPTION (QUERY_PLAN_PROFILE)`

- Update statistics asynchronously with `AUTO_UPDATE_STATISTICS_ASYNC` option

- Automatic Plan Correction can help recommend and fix which type of performance scenario?
  - Query plan regressions that might be caused by **parameter sensitive plans**

### SQL Server

- Alert for log truncation ?
  - SQL Server performance condition alert
- Send email when a SQL Agent job fails, need to:
  - Enable Database Mail
  - Create a Database Mail account
  - Create a Database Mail profile
- DMV for blocking sessions ?
  - `sys.dm_exec_requests`, NOT `sys.dm_exec_sessions`
- In-memory table
  - Is for OLTP, not OLAP


### SQL MI

- Performance degradation, root cause analysis tool ?
  - Intelligent Insights (diag log)

- To resolve high latency in database files ?
  - Increase the file size !

### SQL DB

- Performance related to tempDB
  - Intelligent Insights (diag log)

### Settings

- `OPTIMIZE_FOR_AD_HOC_WORKLOADS` - when a batch is compiled for the first time, save a plan stub instead of full plan in the cache, saves memory

- Database Mail
  - A profile could have multiple SMTP accounts


## Security

- Least previledged role to force a plan in Query Store ?
  - `db_owner`

- For Always Encrypted, the certificate is stored in ?
  - The user DB, not `master`

- Min. TLS version
  - TLS 1.2

- Log access to a specific column
  - Turn on Advanced Data Security (ADS)
  - Apply sensitivity labels
  - Enable auditing

- To view db properties requires:
  - `VIEW DATABASE STATE`

- Azure SQL DB allows you to track and analyze the changes to your data using a feature called **Temporal Tables**
  - Can recover data from a history table

- SQL MI default networking
  - Private


## HA/DR

- Cluster with even number of nodes requires a witness to get quorum

- `MTD` - Maximum tolerable downtime
- `MTO` - Maximum tolerable outage

### PaaS

- Auto-Failover group
  - 1 replica only, NOT the same region
  - A grace period (min. 1 hour), to prevent unnecessary failovers for transient issues

- Geo-replication DMVs
  - `sys.dm_geo_replication_links`: a row for each replication link
  - `sys.dm_geo_replication_link_status`: replication lag


## Backup/restore

- Join a DB to an AG on a secondary ?
  - `RESTORE WITH NORECOVERY`

- Take a full backup from a AlwaysOn AG secondary replica ?
  - Requires the `COPY_ONLY` option
  - CAN'T take `Differential` backup

- Diff backup is **cumulative**, so you only need last full + last diff backup in a restore

- PaaS features:
  - `OFFLINE`, `EMERGENCY` modes NOT allowed
  - `RESTRICTED_USER`, dedicated admin connection (DAC) allowed
  - **Accelerated Database Recovery (ADR)** is a SQL Server database engine feature that greatly improves database availability, especially in the presence of long running transactions, by redesigning the SQL Server database engine recovery process. CAN'T be disabled.

- Best option to determine last good backup ?
  - Audit logs

- Azure SQL DB backup and restore integrity checks
  - Automatic page repair when possible, no notification
  - If an impact, proactive notification

- PaaS does NOT support "SIMPLE" recovery model

## Maintainance

- Fix `CHECKSUM` error:
  - `DBCC CHECKDB ('DB1', REPAIR_ALLOW_DATA_LOSS) with NO_INFOMSGS`

- "Shrink DB" shouldn't be part of regular maintainance, it could cause issues:
  - Index fragmentation
  - Performance degradation

- Azure SQL DB does NOT support online index rebuilds like `ALTER INDEX ... REBUILD WITH (ONLINE=ON)`, except premium/business critical
  - Online does not block reads/writes
