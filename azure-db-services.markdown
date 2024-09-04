# Azure DB services

- [Overview](#overview)
- [MySQL](#mysql)
  - [Modes](#modes)
- [MariaDB](#mariadb)
- [PostgreSQL](#postgresql)
  - [Azure Database for PostgreSQL](#azure-database-for-postgresql)
  - [Modes](#modes-1)
  - [Flexible Server](#flexible-server)


## Overview

This note covers open source DB services: MySQL, MariaDB, PostgreSQL.

See separate notes about
- [SQL DB](./azure-sql-db.markdown)
- [Cosmos DB](./azure-cosmos-db.markdown)


## MySQL

Versions

- Community: free
- Standard: higher performance, different technology for storing data
- Enterprise: comprehensive tools, enhanced security, availability and scalability

Azure Database for MySQL

- Based on Community Edition
- Built-in high availability
- Easy scaling that responds to demand
- Automatic backups and point-in-time restore for the last 35 days
- Firewall rules, lock modes, maximum number of connections
- Monitoring: logs, metrics, alerts
- Enterprise-level security and compliance with legislation

### Modes

- Single server
- Flexible server (recommended)
  - More controls
  - Zone resilient high availability
    - You could specify a zone for the active replica
    - Have a standby replica in a different zone
  - Better cost optimization


## MariaDB

- Compatibility with Oracle Databases
- Built-in support for temporal data: a table can hold several version of data, enabling querying the data as it appeared in the past


## PostgreSQL

- Hybrid relational-object database
- Can store custom data types, with their own non-relational properties
- Extensible: you can add code modules, which can be run by queries
- Store and manipulate geometric data: such as lines, circles, and polygons

### Azure Database for PostgreSQL

- Stored procedures limits: only in pgsql, no other languages, can't interact with OS
- Built-in failure detection and failover mechanisms
- Queries saved in a db called `azure_sys`, you can use a view called `query_store.qs_view` to see the info.

### Modes

- Single server
- Flexible Server (recommended)
  - More controls
  - Zone resilient high availability
    - You could specify a zone for the active replica
    - Have a standby replica in a different zone
  - Better cost optimization

### Flexible Server

- Audit logging
  - To enable, you need to
    - Enable `pgAudit` in `azure.extensions`
    - Add `pgaudit` to `shared_preload_libraries`
    - Restart server
    - Run `CREATE EXTENSION pgaudit;` after connecting to the server
    - Configure other parameters, eg. set `pgaudit.log` to `WRITE`
  - Send to `AzureDiagnostics` table, with category `PostgreSQLLogs`
