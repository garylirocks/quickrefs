## Migration

- On-prem DB with TDE to SQL MI, where to upload TDE cert to ?
  - The MI itself, NOT a key vault

- Online migration using Azure Database Migration Service
  - SQL MI and SQL in VM
  - NOT SQL DB

## Performance

### Indexes

- Nonclustered indexes
  - Enables efficient lookups, reduces full table scans

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
  - Intelligent Insights

- To resolve high latency in database files ?
  - Increase the file size !


## Security

- Least previledged role to force a plan in Query Store ?
  - `db_owner`

- For Always Encrypted, the certificate is stored in ?
  - The user DB, not `master`

- Min. TLS version
  - TLS 1.2


## HA/DR

### PaaS

- Auto-Failover group
  - 1 replica only, NOT the same region

- Geo-replication DMVs
  - `sys.dm_geo_replication_links`: a row for each replication link
  - `sys.dm_geo_replication_link_status`: replication lag


## Backup/restore

- Join a DB to an AG on a secondary ?
  - `RESTORE WITH NORECOVERY`