# Data engineering

## Overview

Data formats

- Structured
- Semi-structured
- Unstructured

Data storage

- Files
  - CSV, TSV
  - JSON
  - XML
  - BLOB (Binary Large Object): images, videos, audios, app-specific documents
  - Optimized formats: *Avro*, *ORC*, *Paraquet*, etc
- Databases
  - Relational
  - Non-relational/NoSQL
    - Key-value: value can be in any format
    - Document: value is in JSON format
    - Column family

      ![Column family DB](images/data_column-family-db.png)

    - Graph

Data processing

- Transactional: OLTP
  - Requires quick read/write
  - Often high-volume
  - Support live applications that process business data - often referred to as *line of business* (LOB) applications
  - CRUD operations: Create, Retrieve, Update, Delete
  - ACID semantics
    - Atomicity: succeeds completely or fails completely
    - Consistency: one valid state to another
    - Isolation: transactions cannot interfere with one another
    - Durability: persisted

- Analytical: OLAP
  - Typically read-only
  - Vast volumes of historical data
  - Data lakes: large volume of files
  - ETL (extract, transform and load) copies data from OLTP into a data warehouse
  - Data warehouses
    - optimized for read operations
    - may require some de-normalization of OLTP data (to make queries faster)
    - *fact* tables contain numeric values (eg. sales revenue), related *dimension* tables contain entities by which to measure the facts (eg. product, location)

    ![Fact vs Dimension](images/data_star-and-snowflake-schema.drawio.svg)
    *Star schema vs. Snowflake schema*