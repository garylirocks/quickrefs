MongoDB
========

- [MongoDB](#mongodb)
    - [Concepts](#concepts)
        - [Field](#field)
    - [Architecture](#architecture)
    - [Connection / Management](#connection--management)
    - [Data Import / Export](#data-import--export)
    - [CRUD](#crud)
        - [Create](#create)
        - [Read](#read)
        - [Update](#update)
        - [Delete](#delete)


## Concepts

[SQL to MongoDB Mapping Chart](https://docs.mongodb.com/manual/reference/sql-comparison/)

SQL to Mongo terminology mapping

```
SQL                 <->         Mongo

database                        database
table                           collection
row                             document
column                          field
index                           index
table joins                     $lookup, embedded documents
primary key                     primary key (automatically set to the _id field)
aggregation (e.g. group by)     aggregaton pipeline
transactions                    transactions
```

### Field

A field can be 

* Scalar value
    * `string` 
    * `int32`
    * `double`
    * `decimal`: for finicial calculations
    * `date`
    * `coordinates`
* Array (its element can be scalar or object);
* Document (object);


## Architecture

![MongoDB Sharding and Replica Set](./images/mongo-sharding-replicaset.png)



## Connection / Management

```sh
# a sample connection command
mongo "mongodb://<domain-1>:27017,<domain-2>:27017,<domain-3>:27017/<dbName>?replicaSet=sampleSet" --authenticationDatabase admin --ssl --username <username> --password <password>

# an equivalent connection string for Mongo v3.6+
mongo "mongodb+srv://<cluster-domain>/<dbName>" --username <username>
```

In the above example, you are:

* Specifying multiple hosts in a `replicaSet`, you will always be connected to the primary host, if the current primary is down, mongo will try to connect to the new primary;
* Specifying a `dbName` to connect to;
* Specifying an auth db;
* Using `--ssl` to enable encryption;


After connection, use `help` to get started

```sh
show dbs            # list all dbs
use <db>            # switch to a db

show tables         # show tables in current db

db.users.drop()     # drop/delete the users table

db.movies.find().pretty()   # add `pretty()` for pretty output, this output 20 documents by default
it                          # output next 20 documents
```


## Data Import / Export

In Mongo shell

```js
# the shell is a JS interpreter, so you can run a js script to load data
load("demoDB.js")
```


## CRUD

### Create

```js
/* providing an _id */
db.scratch.insertOne({_id: 'jack', name: 'jack'})
// { "acknowledged" : true, "insertedId" : "jack" }

/* no _id */
db.scratch.insertOne({name: 'gary'})
// {
// 	"acknowledged" : true,
// 	"insertedId" : ObjectId("5bc6f3183eaaad3eae033ad6")
// }

/* insert many */
db.scratch.insertMany([
        { name: 'jack' }, 
        { name: 'lucy' },
    ], 
    {
        ordered: false,
    });

// {
// 	"acknowledged" : true,
// 	"insertedIds" : [
// 		ObjectId("5bc6f60f3eaaad3eae033ad7"),
// 		ObjectId("5bc6f60f3eaaad3eae033ad8")
// 	]
// }
```

* Use `insertOne` to insert a document;
* If an `_id` is provided, it will be used, otherwise, a unique `_id` of `ObjectId` type will be generated automatically;
* Use `insertMany` to add an array of documents, you can specify a `ordered` option to control whether insert the documents in order or not;


### Read

```js
/* get all */
db.users.find()
// { "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 20 }

/* specify query and fields */
db.users.find( 
    { age: {$gt: 18} },     # query criteria
    {name: 1}               # projection, only get 'name' field
)
// { "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary" }

/* search a nested document */
db.data.find({
    'wind.type': 'N',
    'wind.angle': 290,
}).count();
```

* Multiple queries are joined with `and` logic;
* Use `count()` to get results count;


### Update

```js
> db.users.updateOne(
... { name: {$eq: "gary"} },
... { $set: {age: 30} }
... )
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

> db.users.find()
{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 30 }
```

### Delete

```js
> db.users.deleteOne(
... {age: {$gt: 20}}
... )
{ "acknowledged" : true, "deletedCount" : 1 }

> db.users.find()
> 
```
