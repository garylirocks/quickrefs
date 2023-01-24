# Snowflake

## Overview

You could choose Azure, AWS or GCP as the underlying platform.

Compute and storage are separated

- Compute resources are called **warehouses**, they load, transform, query data
- Storage: data are actually saved in blob storage resources, eg. S3 in AWS, Blob storage in Azure

Hierarchies:

- Organization
- Account
  - each account has its own set of users, roles, databases, and warehouses
  - account properties: cloud, region, edition
- Users


## Databases

```sql
CREATE OR REPLACE DATABASE sample_db_2023;

CREATE OR REPLACE SCHEMA DBO;

CREATE OR REPLACE TABLE population (
    period Date,
    status Varchar(1),
    natural_increase Integer,
    net_migration Integer,
    population_change Integer,
    percent_population_change Float,
    population Integer
);
```


## File format and Stages

- You could define custom file format to load data
- A stage is a temporary location where your data is stored before being loaded into your table

The following example loads a CSV file from Azure Blob storage to a table:

- Create a file format

  ```sql
  CREATE or replace FILE FORMAT puplulation_csv
    TYPE = CSV
    SKIP_HEADER = 1
    EMPTY_FIELD_AS_NULL = true;
  ```

- Create an external stage, pointing to a container in Azure blob, using SAS token as credentials

  ```sql
  CREATE OR REPLACE STAGE stage_population
      url = 'azure://stgarytesting001.blob.core.windows.net/sample-data/'
      credentials = (azure_sas_token='xxxx')
      file_format = puplulation_csv;
  ```

- Query a file in a stage

  ```sql
  // show the file
  LIST '@stage_population/sample-population.csv'

  // query a CSV file
  SELECT
      s.$1 as period,
      s.$2 as status
  FROM '@stage_population/sample-population.csv' AS s
  LIMIT 5;
  ```

- Load data from CSV to a table

  ```sql
  COPY INTO population FROM '@stage_population/sample-population.csv';

  SELECT * FROM population;
  ```


## Warehouses

```sql
CREATE OR REPLACE WAREHOUSE my_wh;

ALTER WAREHOUSE my_wh SET WAREHOUSE_SIZE = 'large';
```


## Data types

- integer
- float
- string: same as `VARCHAR(16777216)`, or `VARCHAR(MAX)` in SQL Server
- date


## Privileges

```
GRANT CREATE STAGE ON SCHEMA public TO ROLE myrole;

GRANT USAGE ON INTEGRATION azure_int TO ROLE myrole;
```


## Loading data from Azure

<img src="images/snowflake_load-data-from-azure-blob.png" width="600" alt="Loading data from Azure blob" />

- Only supports loading data from blobs.
- You can load directly from a container, but it's recommended to create an external stage that reference the container and use the stage instead.
- Requires a running, current virtual warehouse if you execute the command manually or within a script.

### Networking

You could only use storage account firewalls to limit the access to your storage account, you can't use private endpoints, because you **can't create PEP** in Snowflakes subscriptions

- Get Snowflake subnet IDs, `SELECT SYSTEM$GET_SNOWFLAKE_PLATFORM_INFO();`
  - You'll get multiple VNet and subnet IDs
  - These VNets are in Snowflake's subscriptions, you can't access them directly
  - Seems these VNets are shared by all Snowflake Azure accounts
- Add each subnet ID to your storage account firewall: `az storage account network-rule add --account-name <account_name> --resource-group myRG --subnet "<snowflake_vnet_subnet_id>"`
  - This cannot be done in the Portal
  - In the Portal, it would show "Insufficient permissions" warnings, these indicate your storage account may not initiate connections to Snowflake. They will not block the allow feature, could be ignored.


### Security

Two options

1. Recommended: Config a storage integration object, which uses an Azure service principal for authentication
1. Use a SAS token

#### Storage integration object

- Create a cloud storage integration

  ```
  CREATE STORAGE INTEGRATION <integration_name>
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'AZURE'
    ENABLED = TRUE
    AZURE_TENANT_ID = '<tenant_id>'
    STORAGE_ALLOWED_LOCATIONS = ('azure://<account>.blob.core.windows.net/<container>/<path>/', 'azure://<account>.blob.core.windows.net/<container>/<path>/')
    [ STORAGE_BLOCKED_LOCATIONS = ('azure://<account>.blob.core.windows.net/<container>/<path>/', 'azure://<account>.blob.core.windows.net/<container>/<path>/') ]
  ```

  Snowflake actually creates an app for your account in its Azure tenant

- Create a service principal in Azure

  ```
  DESC STORAGE INTEGRATION <integration_name>;
  ```

  Visit the url in `AZURE_CONSENT_URL`, after you consent the required permissions, a service principal would be created in your tenant.

  The service principal usually would be named like `*snowflake*`

- Grant the service principal appropriate roles to the storage accounts, `Storage Blob Data Reader` or `Storage Blob Data Contributor`

- Create an external stage

  ```
  USE SCHEMA mydb.public;

  CREATE STAGE my_azure_stage
    STORAGE_INTEGRATION = azure_int
    URL = 'azure://myaccount.blob.core.windows.net/container1/path1'
    FILE_FORMAT = my_csv_format;
  ```