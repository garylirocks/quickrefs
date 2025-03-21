# Kusto Query Language

- [Data types](#data-types)
  - [`dynamic` data type](#dynamic-data-type)
- [Simple operations](#simple-operations)
  - [`project`](#project)
  - [Text matching](#text-matching)
  - [Datetime](#datetime)
- [Advanced operations](#advanced-operations)
  - [`range`](#range)
  - [`as`](#as)
- [Functions](#functions)
- [Variables and custom functions](#variables-and-custom-functions)
- [Aggregation](#aggregation)
- [Time series](#time-series)
- [Multi-table queries](#multi-table-queries)
- [Schema](#schema)
- [Create a table](#create-a-table)
- [Visualization](#visualization)
- [Geospatial](#geospatial)
  - [GeoJSON](#geojson)
  - [Functions](#functions-1)
  - [Plot points on a map](#plot-points-on-a-map)
  - [Variable-sized bubbles](#variable-sized-bubbles)


## Data types

Two categories:
  - Scalar data type: bool, int, string, datetime, dynamic, ...
  - User-defined record: an ordered sequence of name/scalar-data-type pairs, such as the data type of a row of a table

All non-string data type includes a special "null" value, could be tested using `isnull()` function.

### `dynamic` data type

Could be `null`, any other scalar data type, or an array, property bag (aka. map, object) of other dynamic values


## Simple operations

### `project`

- Select and rename columns, other columns excluded

  ```kusto
  | project NewCol=OldCol, SumCol=ColA+ColB
  ```

- Add new columns

  ```kusto
  | extend NewCol=OldCol * 2
  ```

- Exclude columns (supporting wildcard)

  ```kusto
  project-away *Id, *Time
  ```

### Text matching

  - `has` matches on a full term, more performant, case-insensitive

  ```kusto
  | where ColA has "gary"
  ```

  - `contains` matches on any substring

  ```kusto
  | where ColA contains "gary"
  ```

  - regex

  ```kusto
  | where ColA matches regex @'.*gary.*'
  ```

  - `search` searches a text pattern in multiple tables and columns

  ```kusto
  // Search a term in all columns of the two tables
  search in (Customers, SalesTable) "Green"

  // regex match a specified column
  search col1 matches regex "..."
  ```


### Datetime

  ```kusto
  | where StartTime between (datetime(2023-01-01)..datetime(2023-03-01))
  ```


## Advanced operations

### `range`

  ```kusto
  // a number column
  range myCol from 1 to 10 step 2

  // a datetime range
  range myCol from ago(4h) to now() step 1h
  ```

### `as`

  Put tabular input into a variable within a query, the variable could be used later in the query, this saves you from spliting the query and defining a variable using `let`.

  ```kusto
  let People = datatable(FirstName:string, LastName:string, Age:int)
  [
      "John", "Doe", 35,
      "Jane", "Doe", 30,
      "Bob", "Smith", 45,
      "Alice", "Johnson", 28,
      "Mike", "Brown", 50,
      "Samantha", "Davis", 25,
      "Tom", "Wilson", 42,
      "Sarah", "Jones", 33,
      "David", "Garcia", 39,
      "Emily", "Taylor", 29
  ];
  People
  | summarize count() by bin(Age, 10)
  | as hint.materialized=true Table
  | sort by Age asc
  | extend total=toscalar(Table | summarize sum(count_))
  | extend percentage = (count_ * 100 / total)
  ```

  ```
  Age   count_   total    percentage
  20    3        10       30
  30    4        10       40
  40    2        10       20
  50    1        10       10
  ```

  `hint.materialized=true` caches the result, without it, the expression would be re-calculated everytime it appears

  ```kusto
  range x from 1 to 100 step 1
  | sample 1
  | as T
  | union T
  ```

  might result in

  ```
  X
  63
  62
  ```

  while

  ```kusto
  range x from 1 to 100 step 1
  | sample 1
  | as hint.materialized=true T
  | union T
  ```

  will result in something like

  ```
  X
  95
  95
  ```


## Functions

- `prev()`, `next()`

  ```kusto
  PrimeNumbers
  | top 10 by number asc
  | extend gap = number - prev(number, 1, 0)

  # 2   2
  # 3   1
  # 5   2
  # 7   2
  # 11  4
  ```


## Variables and custom functions

Use `let` to define variables (scalar or tabular), and functions

```kusto
let MinDamage = 1; // int
let EventLocation = "ARIZONA"; // string

// convert tabular to scalar
let MostFrequentEventType = toscalar(
    BooksTable
    | summarize count() by Genre
    | top 1 by count_
    | project Genre);

// function
let Pcent = (portion:real, total:real){round(100 * portion / total, 2)};
```

To create a **saved function**

```kusto
.create-or-alter function
    with (docstring = "My custom function")
    Pcent(portion:real, total:real) {
        round(100 * portion / total, 2)
}
```


## Aggregation

- `summarize`, all elements are grouped by the same column(s) after `by`, other columns are dropped.

  ```kusto
  BooksTable
  | summarize Count_Total = count(),
      Count_Fiction = countif(Type == "fiction"),
      Count_Language = dcount(Language) by PublishYear
  | sort by Count_Total
  ```

- `arg_max`, `arg_min`, could be used to keep other columns

  ```sql
  # The latest heartbeat for each computer, the '*' means all columns are kept
  Heartbeat
  | summarize arg_max(TimeGenerated, *) by ComputerIP
  ```

- `mv-expand`, expand arrays/property bags

  ```kusto
  datatable (a:int, b:dynamic) [
    1, dynamic({"name": "gary", "age": 20})
  ]
  | mv-expand b
  ```

  returns:

  ```
  1	{"name":"gary"}
  1	{"age":20}
  ```

  Or you can expand a property bag into arrays

  ```kusto
  datatable (a:int, b:dynamic) [
    1, dynamic({"name": "gary", "age": 20})
  ]
  | mv-expand bagexpansion=array b
  ```

  returns:

  ```
  1	["name", "gary"]
  1	["age", 20]
  ```

- `mv-apply`, does `mv-expand` first, which create a subtable for each row, then apply a subquery on the subtable, then return the union of the results

  ```kusto
  datatable (id:int, arrayCol:dynamic) [
    1, dynamic([1,3,5,7]),
    2, dynamic([2,4,6,8])
  ]
  | mv-apply elementCol=arrayCol to typeof(long) on
    (
      top 2 by elementCol
      | summarize SumOfTop2=sum(elementCol)
    )
  ```

  returns:

  ```
  1	[1,3,5,7]	12
  2	[2,4,6,8]	14
  ```


## Time series

```kusto
StormEvents
| summarize count() by category, bin(StartTime, 1d)
| render timechart with(series = category)

StormEvents
| summarize count() by bin(StartTime, 7d)
| render columnchart
```


## Multi-table queries

- Types of tables:
  - **Fact tables**: like Sales, which do not change, often have foreign keys to dimension tables
  - **Dimension tables**: like Customers, Products, the data changes
- `join`
  - Syntax: `| join kind=inner RightTable on $left.id == $right.id2`
  - For best performance, use the table with less rows as the left one
  - See diagram below for kinds of join
    - `innerunique` keeps the first row of each unique value of the matching column, this row is duplicated if the value is duplicated in the right table
    - `leftsemi`, `leftantisemi` only keep columns from left table, the former keeps rows which has a match in the right table, the latter keeps un-matching rows

    ![Kinds of join](./images/azure_kql-kinds-of-join.svg)

- `lookup` works like `leftouter`, it's optimized for getting looking up data from dimension tables

    ```kusto
    SalesFact
    | lookup Customers on CustomerKey
    | take 10
    ```

- Combine tables
  - `union TABLE_A TABLE_B` keeps all columns
  - `union inner TABLE_A TABLE_B` only keep common columns

- `materialize()` caches the results in memory, so that other parts of the query can reference the result, otherwise the subquery will be calculated everytime, leading to non-deterministic results

  ```kusto
  let ResultTable = materialize(
      TABLE
      | summarize ...);
  ResultTable
  | query ...
  ```


## Schema

```kusto
// get table schema
TABLE_NAME
| getschema
```


## Create a table

- Temporary table

  ```kusto
  // generated by ChatGPT :D
  datatable (Author:string, Title:string, Genre:string, Year:int)
  [
      "Harper Lee", "To Kill a Mockingbird", "Fiction", 1960,
      "F. Scott Fitzgerald", "The Great Gatsby", "Fiction", 1925,
      "Jane Austen", "Pride and Prejudice", "Romance", 1813,
  ]
  ```

- Persisted table and data ingestion

  ```kusto
  .execute database script <|
  // dynamic is just like any other type:
  .create table Logs (Timestamp:datetime, Trace:dynamic)
  // values in `[]` are in CSV format,
  // the JSON string is quoted in double quotes, the double quotes within it need to be doubled up
  .ingest inline into table Logs
    [2015-01-01,"{""EventType"":""Demo"", ""EventValue"":""Double-quote love!""}"]
  ```

  Or ingest a CSV file

  ```kusto
  .ingest into table PrimeNumbers ('https://example.com/prime-numbers.csv.gz') with (ignoreFirstRecord=true)
  ```


## Visualization

```kusto
StormEvents
| summarize Count_total = count(),
    Count_type = dcount(EventType) by State
| top 3 by Count_total asc
| render columnchart
```


## Geospatial

### GeoJSON

[GeoJSON](https://www.rfc-editor.org/rfc/rfc7946) is used to represent geospatial entities, for example:

```json
// point
dynamic({
  "type": "Point",
  "coordinates": [100.0, 0.0]
})

// lineString
dynamic({
  "type": "LineString",
  "coordinates": [
    [100.0, 0.0],
    [101.0, 1.0]
  ]
})

// polygon without holes
dynamic({
  "type": "Polygon",
  "coordinates": [
    [
      [100.0, 0.0],
      [101.0, 0.0],
      [101.0, 1.0],
      [100.0, 1.0],
      [100.0, 0.0]
    ]
  ]
})

// polygon with holes, the first element represents the outer ring,
//  subsequent elements represent inner rings (holes)
dynamic({
  "type": "Polygon",
  "coordinates": [
    [
      [100.0, 0.0],
      [101.0, 0.0],
      [101.0, 1.0],
      [100.0, 1.0],
      [100.0, 0.0]
    ],
    [
      [100.8, 0.8],
      [100.8, 0.2],
      [100.2, 0.2],
      [100.2, 0.8],
      [100.8, 0.8]
    ]
  ]
})
```

### Functions

- `geo_point_in_circle` whether a point is in a circle

  ```kusto
  geo_point_in_circle(latitude, longitude, center_latitude, center_longitude, radius)
  ```

- `geo_point_in_polygon` whether a point is in a polygon

  ```kusto
  let southern_california = dynamic({
      "type": "Polygon",
      "coordinates": [[[-119.5, 34.5], [-115.5, 34.5], [-115.5, 32.5], [-119.5, 32.5], [-119.5, 34.5]]
      ]});
  StormEvents
  | where geo_point_in_polygon(BeginLon, BeginLat, southern_california)
  ...
  ```

- Geospatial clustering

  Three methods are supported: Geohash, S2 Cell, H3 Cell, see details here https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/geospatial-grid-systems

  For Geohash, the level parameter dictates the length of the hash string. If two hashes has common prefixes, they are close to each other, but it's not true other way around: two close points may not have a common hash prefixs

  ```kusto
  print geo_point_to_geohash(174.762191, -36.848448, 2), geo_point_to_geohash(174.762191, -36.848448, 6), geo_point_to_geohash(174.762191, -36.848448, 10);

  # print_0  print_1  print_2
  # rc       rckq2g   rckq2gcynp
  ```

  A **common pattern for clustering**, calculate the hash, then get the central point:

  ```kusto
  StormEvents
  | project BeginLon, BeginLat
  | summarize by hash=geo_point_to_s2cell(BeginLon, BeginLat, 5)
  | project geo_s2cell_to_central_point(hash)
  | render scatterchart with (kind=map)
  ```


### Plot points on a map

Plot multiple series of points on a map

```kusto
StormEvents
| take 100
| project BeginLon, BeginLat, EventType
| render scatterchart with (kind = map)

// same as
StormEvents
| take 100
| render scatterchart with (kind = map, xcolumn = BeginLon, ycolumns = BeginLat, series = EventType)
```

![Map with series](images/kql_map-with-series.png)

### Variable-sized bubbles

Use `piechart` to plot variable-sized pies on a map (*only in Kusto Explorer Desktop*)

```kusto
StormEvents
| where EventType in~ ("Lightning", "Tornado", "Flood")
| project BeginLon, BeginLat, EventType
| where isnotnull(BeginLat) and isnotnull(BeginLon)
| summarize count() by hash = geo_point_to_s2cell(BeginLon, BeginLat, 4), EventType
| project geo_s2cell_to_central_point(hash), EventType, count_
| render piechart with (kind = map)
```

![Map with variable-sized bubbles](images/kql_map-variable-sized-bubbles.png)
