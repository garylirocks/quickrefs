MongoDB
========

- [Concepts](#concepts)
    - [`BSON`](#bson)
    - [Field](#field)
- [Architecture](#architecture)
- [Connection / Management](#connection--management)
- [Data Import / Export](#data-import--export)
- [CRUD](#crud)
    - [Create](#create)
    - [Read](#read)
        - [Sort / Skip / Limit](#sort--skip--limit)
    - [Update](#update)
        - [Upsert](#upsert)
        - [Replace](#replace)
    - [Delete](#delete)
- [Query Language](#query-language)
    - [Array](#array)
    - [Regex](#regex)
    - [Geospatial](#geospatial)
- [NodeJS](#nodejs)
- [Schema design](#schema-design)
- [Storage Enginge](#storage-enginge)
- [Indexes](#indexes)
    - [Create Indexes](#create-indexes)
        - [Creation Mode](#creation-mode)
    - [Single field indexes](#single-field-indexes)
    - [Compound indexes](#compound-indexes)
    - [Full text index](#full-text-index)
    - [Explain](#explain)
    - [Covered queries](#covered-queries)
- [Performance](#performance)
    - [Hardware Condsiderations](#hardware-condsiderations)
    - [Profiling](#profiling)


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

### `BSON`

* `BSON` means binary JSON, is a binary-encoded serialization of JSON-like documents; 
* MongoDB data is stored and transfered in this format; 
* It supports more data types than JSON, such as a Date type, a BinData type, an ObjectId type (for the `_id` field);


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
it                          # iterate over the next 20 documents
```

* `find()` actually returns an iterator, you can use `next()`, `hasNext()` on it

```sh
var r = db.movieDetails.find({});
r.hasNext()
```


## Data Import / Export

Use `mongoimport`, specify database and collection name

```sh
mongoimport -d crunchbash -c companies companies.json
```

In Mongo shell, using `load`

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
    { name: 1 }               # projection, only get 'name' field
)
// { "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary" }

/* search a nested document */
db.data.find({
    'wind.type': 'N',
    'wind.angle': 290,
}).count();

/* search an array field */
db.data.find({ actors: 'Julia Roberts' });  // any position in an array

/* $or operator */
db.data.find({
    $or: [
        { 'actors': 'Julia Roberts' }, 
        { 'year': 2010 }
    ]}
);
```

* Multiple queries are joined with `and` logic;
* Use `count()` to get results count;
* The second parameter is a projection field, which controls which fields are returned, use `1` to include a field, `0` to exclude it (`_id` is included by default, you can exclude it explicitly);

#### Sort / Skip / Limit

```js
db.movieDetails.find({
    'rated': 'PG-13'
}).sort({
    'year': 1,              // increasing order
    'awards.wins': -1       // decreasing order
}).skip(10).limit(5);
```

* MongoDB always do it in this order: `sort()`, `skip()`, `limit()`, even you put `limit()` at the first;
* In the NodeJS driver, the sorting document can be an array:

    ```js
    cursor.sort([
        ["founded_year", 1], 
        ["number_of_employees", -1]
    ])
    ```


### Update

```js
/* update the first matching document */
db.users.updateOne(
    { name: {$eq: "gary"} },
    { $set: {age: 30} }
    )
// { "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

db.users.find()
// { "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 30 }

/* update all matching documents: remove the rated field if it is null */
db.movies.updateMany(
    { rated: null },
    { $unset: { rated: "" }}
)
```

* Update operators: `$currentDate`, `$inc`, `$min`, `$max`, `$mul`, `$rename`, `$set`, `$setOnInsert`, `$unset`; 
* Array operators: `$`, `$[]`, `$[<identifier>]`, `$addtoSet`, `$pop`, `$pull`, `$push`, `$pushAll`;
* Array modifiers: `$each`, `$position`, `$slice`, `$sort`;

See here https://docs.mongodb.com/manual/reference/operator/update/

#### Upsert

```js
/* insert if no match found */
db.movies.updateOne({ 
    name: 'Notting Hill' 
}, { 
    $set: { 
        name: 'Notting Hill',
        rating: 5,
    },
}, { 
    upsert: true,
});
```

#### Replace

```js
/* replace the whole document, it lets you work on multiple fields, and then replace the whole */
theMovie = db.movies.find({ name: 'Notting Hill' });
theMovie.rating = 10;
theMovie.cast = [ 'Julia Roberts' ];

db.movies.replaceOne({ 
    name: 'Notting Hill' 
}, 
    theMovie,
);
```
  

### Delete

```js
/* delete first one */
db.users.deleteOne({
    age: {$gt: 20}
});
// { "acknowledged" : true, "deletedCount" : 1 }

/* delete all matching documents */
db.users.deleteMany({
    age: {$gt: 20}
});
```

## Query Language

### Array

```js
// at least one element in the actors array is 'Julia Roberts'
db.data.find({ actors: 'Julia Roberts' });

// actors array has 3 elements
db.data.find({ actors: { $size: 3 } });

// the first element in the actors array is 'Julia Roberts'
db.data.find({ 'actors.0': 'Julia Roberts' );

// !!!THIS IS USUALLY NOT WHAT WE WANT: 
//      there is one element >= 70 and one element < 80
db.scores.find({ results: { $gte: 70, $lt: 80 } });

// CORRECT WAY TO APPLY MULTI CONDITIONS ON ONE ELEMENT
//      at least one element of the results array >= 70 and < 80
db.scores.find({ results: { $elemMatch: { $gte: 70, $lt: 80 } } });
```

### Regex

```js
db.companies.find({'name': /facebook/i});

// equivalent to
db.companies.find({
    name: {
        $regex: 'facebook',
        $options: 'i'           // case insensitive
    }});
```

### Geospatial

```js
// use '$near' to find places near a location, from closest to furthest
db.places.find({'location': {$near: [74, 140]}}).limit(3);
```

## NodeJS

```js
var MongoClient = require('mongodb').MongoClient,
    assert = require('assert');

MongoClient.connect('mongodb://localhost:27017/crunchbase', function(err, db) {
    assert.equal(err, null);
    console.log("Successfully connected to MongoDB.");

    var query = {"category_code": "biotech"};

    db.collection('companies').find(query).toArray(function(err, docs) {
        assert.equal(err, null);
        assert.notEqual(docs.length, 0);
        
        docs.forEach(function(doc) {
            console.log( doc.name + " is a " + doc.category_code + " company." );
        });
        
        db.close();
    });
});
```

explicit cursor


```js
...
var query = {"category_code": "biotech"};
var projection = {"name": 1, "category_code": 1, "_id": 0};

var cursor = db.collection('companies').find(query);
cursor.project(projection);

cursor.forEach(
    function(doc) {
        console.log( doc.name + " is a " + doc.category_code + " company." );
    },
    function(err) {                     // error or the end of results
        assert.equal(err, null);
        return db.close();              // close connection here
    }
);
...
```

* In the above examples, `find()` returns a cursor object, which has methods like `project()`, `toArray()` and `forEach()`;
* The cursor is getting results back in batches, not all in one go;
* The query is not triggered immediately after the cursor is created, it only fires when the result is needed;
* The `project()` method modifies the cursor, the projection document can be passed to `find()` directly as well;

## Schema design

In relational database, we used to keep db schema in the thrid normal form;

For MongoDB, the first principle is making the schema matching the data access pattern of your application, e.g. what data need to be read together;

Differences to relational DB:

* no foreign key constraints;
* no transactions, it does have atomic operations within a single document, so you can:
    * restructure your data, so only need to update one document;
    * implement transaction in your application;
    * tolerate some inconsistency;

Constraints

* Document size (16MB ?);


## Storage Enginge

A storage engine controls how data and index are stored in a disk, not related to cluster structure, db driver, etc;

* MMAPv1
    * Use the `mmap` system call, which maps files to memory;
    * Collection-level locking: one write at a time for a collection;

* WiredTiger

    * Default since MongoDB v3.2;
    * Document-level concurrency, usually faster than MMAPv1;
    * Offers compression of data and indexes;


## Indexes

### Create Indexes

```js
// get indexes of a collection
db.students.getIndexes();

// create a compound index
db.students.createIndex({ student_id: 1, class_id: -1 });

// create a unique index
db.students.createIndex({ student_id: 1 }, { unique: true });

// create a sparse index, if `email` is missing for a document, that document won't be added to the index
db.students.createIndex({ email: 1 }, { unique: true, sparse: true });
```

For a schema like this:

```js
{
    name: 'Gary',
    tags: ['reading', 'skipping', 'learning'],
    color: 'blue',
    location: ['NZ', 'CN'],
    scores: [{
            class: 'Math',
            score: 30,
        }, {
            class: 'History',
            score: 66,
        }]
}
```

* `{'tags': 1}`: a multikey index; 
* `{'tags': 1, 'color': 1}` is valid;
* `{'tags': 1, 'location': 1}` is **NOT** valid, can't use two array fields in one key;

#### Creation Mode

* Foreground:
    * default option;
    * fast;
    * blocks writes and reads on database level;

* Background
    * don't block;

    ```js
    db.students.createIndex({ student_id: 1 }, { background: true });
    ```

### Single field indexes

```js
db.foo.createIndex({ age: 1 });

// on a sub field
db.foo.createIndex({ people.age: 1 });
```

An index like this `{ age: 1 }` can be used for these queries:

* Query
    * `{ age: 20 }`;
    * `{ age: { $gt: 20, $lt: 30 } }`: filter by range;
    * `{ age: { $in: [ 20, 30, 40 ] } }`: filter by distinctive values;
    * `{ age: { $in: [ 20, 30, 40 ] }, name: 'Gary' }`: `IXSCAN` on the `age` index, then filter by `name`;

* Sort
    * `.find({ name: 'Gary' }).sort({ age: 1 })`: `IXSCAN` on the `age` index for sorting, then filter by `name`;
    * `.find({ name: 'Gary' }).sort({ age: -1 })`: backword `IXSCAN` on the `age` index for sorting;
    * `.find({ age: { $gt: 20 } }).sort({ age: 1 })`: `IXSCAN` for both sorting and filtering;

### Compound indexes

For an index `{a: 1, b: 1, c: 1}`, to use it:

* Queried fields must be a **prefix** of the indexed fileds:

    * `{ a: 20 }`; 
    * `{ a: 20, b: 30 }`;
    * `{ a: 20, b: 30, c: 40 }`;
    * `{ a: 20, b: { $gte: 30 } }`;
    * `{ a: { $lte: 20 }, c: { $gte: 30 } }`: `keysExamined` will be larger than `docsExamined`;
    * **NOT** used for:
        * `{ b: { $lte: 20 } }`;
        * `{ b: { $lte: 20 }, c: 30 }`;

* For sorting

    * `.find().sort({ a: 1, b: 1 })`: index prefix;
    * `.find().sort({ a: -1 })`: `b` will be sorted backwards;
    * `.find().sort({ a: -1, b: -1 })`: invert;
    * `.find({ a: 20 }).sort({ b: 1 })`: `a` is an equality predicate and is before `b` in the index;
    * `.find({ a: 20, c: { $gt: 20 } }).sort({ b: 1 })`: `a` is an equality predicate and is before `b` in the index;
    * **NOT** used for:
        * `.find().sort({ b: 1, a: 1 })`;
        * `.find().sort({ a: 1, b: -1 })`;
        * `.find().sort({ a: -1, b: 1 })`;
        * `.find().sort({ a: 1, c: 1 })`;
        * `.find().sort({ a: 1, c: 1 })`;
        * `.find({ a: { $gt: 20 }}).sort({ b: 1 })`: `a` is a range predicate, the index can be used for filtering but not sorting;

**Equality fields first, then sort fields, then range fields**


### Full text index

```js
// create a text index
db.foo.createIndex({'description': 'text'});

// search against the index (case insensitive), not every word need to be present in the record
db.foo.find({$text: {$search: 'football dog'}})

// sort by text maching score
db.foo.find({$text: {$search: 'football dog'}}, {score: {$meta: 'textScore'}}).sort({score: {$meta: 'textScore'}})
```

### Explain

Use `explain()` to show how query is executed:

```js
db.movies.explain().find({'title': 'Jaws'})

// equivalent to
var exp = db.movies.explain();
exp.find({'title': 'Jaws'});
```

* `explain()` returns an explainable object, which can then be used with a lot of operations, like `find()`, `count()`, `update()`, `remove()`, `group()`, `aggregate()` etc;

* The old syntax is using `explain()` on a cursor object, like:

    ```js
    db.movies.find({'title': 'Jaws'}).explain();
    ```

    but it doesn't work for `count()` which doesn't return a cursor object;

* Three levels of verbosity:

    * `queryPlanner`: don't actually exec the winning plan;
    * `executionStats`: do exec the winning plan and return stats;
    * `allPlansExecution`: more verbose, show info about rejected plans;

* Stages:

    * `COLLSCAN`: scan all the documents;
    * `IXSCAN`: scan the index;
    * `FETCH`: fetch document after `IXSCAN`;
    * `SORT`: in memory sort, expensive operation, try to avoid this;
    * `PROJECTION`: transform data to needed form; 

### Covered queries

A covered query is a query that is covered by an index, no need to go to read any document (`totalDocsExamined` in explain is 0);

If a collection has schema like this:

```js
{
    _id: 1,
    name: 'Gary',
    age: 20,
}
```

and there is a index `{name: 1, age: 1}`, for the following queries:

* `.find({name: 'Gary', age: 20})`: NOT COVERED; 
* `.find({name: 'Gary', age: 20}, {_id: 0})`: NOT COVERED, MongoDB doesn't know whether there is any field not covered by the index; 
* `.find({name: 'Gary', age: 20}, {_id: 0, name: 1, age: 1})`: COVERED, all needed fields are covered by the index; 

So, inorder for a query to be covered, you need to be **explicit about needed fields, (`_id` need to be suppressed explicitly)**;


## Performance

### Hardware Condsiderations

* RAM (most db operations are done in the RAM), the larger and faster, the better;
* CPU, benefit from multi-core CPUs;
* Disk, IOPS matters, SSD is better than SATA, RAID 10 is the suggested RAID architecture;
* Networking;

### Profiling

```js
// show status
db.getProfilingStatus()

// turn off profilling
db.getProfilingLevel(0)

// log queries taken longer than 22ms
db.setProfilingLevel(1, {slowms: 22})

// log all queries
db.setProfilingLevel(2)

// profilling data are in 'system.profile' collection, use 'ns' key to limit to queries against a paticular collection
db.system.profile.find({ns: /test.foo/})
```
