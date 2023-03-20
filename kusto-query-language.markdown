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
- [Aggregation](#aggregation)
- [Time series](#time-series)
- [Visualization](#visualization)
- [Variables and functions](#variables-and-functions)
- [Multi-table queries](#multi-table-queries)
- [Schema](#schema)
- [Create a table](#create-a-table)


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

  `hint.materialized=true` caches the result

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


## Aggregation

- `summarize`, all elements are grouped by the same column(s) after `by`, other columns are dropped.

```kusto
BooksTable
| summarize Count_Total = count(),
    Count_Fiction = countif(Type == "fiction"),
    Count_Language = dcount(Language) by PublishYear
| sort by Count_Total
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

- `mv-apply`, does `mv-expand` first, then apply a subquery on the subtable, then return the union of the results

  ```kusto
  datatable (a:int, b:dynamic) [
      1, dynamic([1,3,5,7]),
      2, dynamic([2,4,6,8])
  ]
  | mv-apply newCol=b to typeof(long) on
      (
          top 2 by newCol
          | summarize SumOfTop2=sum(newCol)
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
| summarize count() by bin(StartTime, 1d)
| render timechart

StormEvents
| summarize count() by bin(StartTime, 7d)
| render columnchart
```


## Visualization

```kusto
StormEvents
| summarize Count_total = count(),
    Count_type = dcount(EventType) by State
| top 3 by Count_total asc
| render columnchart
```

## Variables and functions

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

- `materialize` function caches the results of a subquery when it runs, so that other parts of the query can reference the partial result, **`let` by itself only represents the query, it does not cache the result**

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
  // dynamic is just like any other type:
  .create table Logs (Timestamp:datetime, Trace:dynamic)

  // values in `[]` are in CSV format,
  // the JSON string is quoted in double quotes, the double quotes within it need to be doubled up
  .ingest inline into table Logs
    [2015-01-01,"{""EventType"":""Demo"", ""EventValue"":""Double-quote love!""}"]
  ```
