MongoDB
========

- [Concepts](#concepts)
    - [`BSON`](#bson)
    - [Field](#field)
- [Connection / Management](#connection--management)
    - [`mongod`](#mongod)
    - [connection](#connection)
    - [`mongo` shell](#mongo-shell)
    - [Other CLI tools](#other-cli-tools)
    - [Security](#security)
    - [Authentication mechanisms](#authentication-mechanisms)
    - [Authorization](#authorization)
        - [Built-in roles](#built-in-roles)
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
- [Replica Set](#replica-set)
    - [Start a Replica Set](#start-a-replica-set)
    - [reconfig a running replica set](#reconfig-a-running-replica-set)
    - [`local` DB](#local-db)
    - [Write concern levels](#write-concern-levels)
    - [Read concern levels](#read-concern-levels)
    - [Read Preference](#read-preference)
- [Sharding](#sharding)
    - [Shard key](#shard-key)
- [Indexes](#indexes)
    - [Create Indexes](#create-indexes)
        - [Creation Mode](#creation-mode)
    - [Single field indexes](#single-field-indexes)
    - [Compound indexes](#compound-indexes)
    - [Multikey indexes](#multikey-indexes)
    - [Partial index](#partial-index)
    - [Full text index](#full-text-index)
    - [Explain](#explain)
    - [Covered queries](#covered-queries)
- [Performance](#performance)
    - [Hardware Condsiderations](#hardware-condsiderations)
    - [Profiling](#profiling)
- [Aggregation](#aggregation)
    - [Overview](#overview)
    - [`$match` stage](#match-stage)
    - [`$project`](#project)
    - [`$addField`](#addfield)
    - [`$geoNear`](#geonear)
    - [cusor-like stages](#cusor-like-stages)
    - [`$sample`](#sample)
    - [`$group`](#group)


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


## Connection / Management

### `mongod`

```sh
mongod --port 27000 --dbpath '/data/db' --bind_ip "192.168.103.100,localhost" --auth
```

Options:

* `--port`;
* `--dbpath`;
* `--bind_ip`: ips to bind to;
* `--auth`: enable authentication;
* `--logpath`;
* `--fork`: start in bac￼kground;

all options can be configed ina YAML file:

```yaml
storage:
  dbPath: /var/mongodb/db

systemLog:
  destination: file
  logAppend: true
  path: /var/mongodb/db/mongod.log

net:
  port: 27000
  bindIp: 192.168.103.100,127.0.0.1

security:
  authorization: enabled

processManagement:
  fork: true

operationProfiling:
   mode: slowOp
   slowOpThresholdMs: 50
```

then start `monogd` with this config file

```sh
mongod --config-file mymongod.conf
```


### connection

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

### `mongo` shell

After connection, use `help` to get started

```sh
show dbs            # list all dbs
use <db>            # switch to a db

show tables         # show tables in current db

use admin
db.shutdownServer() # shut down the server
```

```js
// this is the underlying command, others are shell helper commands that use this one
db.runCommand()

// db
db.dropDatabase()
db.createCollection()

// user
db.createUser()
db.dropUser()

// collection
db.<collection>.renameCollection()
db.<collection>.createIndex()
db.<collection>.drop()

// find
db.movies.find().pretty()   # add `pretty()` for pretty output, this output 20 documents by default
it                          # iterate over the next 20 documents

// load a javascript file
load('./my.js')
```

* `find()` actually returns an iterator, you can use `next()`, `hasNext()` on it

```sh
var r = db.movieDetails.find({});
r.hasNext()
```

### Other CLI tools

* `mongostat`
* `mongodump`

    ```sh
    # dump in BSON format
    mongodump --db applicationData --collection products
    ```

* `mongorestore`

    ```sh
    # '--drop' drops existing data
    mongorestore --drop dump/
    ```

* `mongoexport`

    ```sh
    # export in JSON format
    mongoexport --db applicationData --collection products -o products.json
    ```

* `mongoimport`

    ```sh
    # import with auth options
    mongoimport --port 27000 \
                -u my-user \
                -p my-pass \
                --authenticationDatabase=admin \
                --drop  \
                -d applicationData \
                -c products \
                ./products.json
    ```

### Security

```sh
# enable authentication, if no user exists
#   only connections from localhost are allowed
#   after the first user is created, you need to use it
mongod --auth
```

```sh
# add a user to 'admin'
mongo admin --eval '
  db.createUser({
    user: "root",
    pwd: "root-pass",
    roles: [
      { role: "root", db: "admin" }
    ]
  })
'

# connect, authenticating agains the 'admin' db
mongo --username gary \
        --password \
        --authenticationDatabase admin
```

* It's recommended to create all users in the `admin` database;

### Authentication mechanisms

* SCRAM (basic)
* X.509
* LDAP (enterprise only)
* Kerberos (enterprise only)

### Authorization

Role Based Access Control (RBAC):

* Each user has one or more **Roles**;
* Each **Role** has one or more **Privileges**;
* A **Privilege** represents a group of **Actions** and the **Resources** those actions apply to;

```sh
# grand a role to a user:
db.grantRolesToUser("dba",  [
    { db: "playground", role: "dbOwner" }
];

# show role privileges:
db.runCommand({
    rolesInfo: { role: "dbOwner", db: "playground" },
    showPrivileges: true
})
```

#### Built-in roles

* `root`

* `read`

* `readWrite`

    ```sh
    # create in 'admin' db
    use admin

    # grant 'readWrite' privilege in 'appData' db
    db.createUser({
        user: "app",
        pwd: "app-pass",
        roles: [
            { role: "readWrite", db: "appData" }
        ]
    });
    ```

* `userAdmin`

    privileges include: `createRole`, `dropRole`, `createUser`, `dropUser`, `grantRole`, `revokeRole` etc;

* `dbAdmin`

    privileges include: `dbStats`, `listIndexes`, `collMod` etc;

* `dbAdminAnyDatabase`

    applies to any database;


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

/* add a new entry to the reviews array */
db.item.updateOne(
    { _id: 12 },
    { $push: {
        reviews: {
            name: 'Gary',
            comment: 'a testing comment',
            stars: 3,
            date: 1455800194995
        }
    }});

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

// contains both actors
db.data.find({ actors: { $all: ['Julia Roberts', 'Hugh Grant'] } });

// the first element in the actors array is 'Julia Roberts'
db.data.find({ 'actors.0': 'Julia Roberts' );

// !!!THIS IS USUALLY NOT WHAT WE WANT:
//      there is one element >= 70 and one element < 80
db.scores.find({ results: { $gte: 70, $lt: 80 } });

// CORRECT WAY TO APPLY MULTI CONDITIONS ON ONE ELEMENT
//      at least one element of the results array >= 70 and < 80
db.scores.find({ results: { $elemMatch: { $gte: 70, $lt: 80 } } });

// actors don't contain either of them
db.data.find({
    actors: {
        $not: {
            $elemMatch: {
                $in: ['Julia Roberts', 'Hugh Grant']
            }
        }
    }
});
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


## Replica Set

* MongoDB uses statement replication (**oplog**) instead of binary replication (requires each node has the same OS, architecture, db version);
* Each statement is transformed to be **idempotent**, making sure it can be applied multiple times and get the same result;
* A replica set should
    * contain at least 3 nodes, up to 50;
    * up to 7 nodes can be voting members (so election won't take too much time);
* A node can be set to be an **arbiter**, which doesn't hold any data, only used in an election arbiter;
* A node can be **hidden**, which means it syncs the data, but won't be seen by an application, a hidden node can vote;
* A hidden node can be set to be **delayed**, useful for **hot backup**: e.g., if a node is delayed for 1 hour, and someone deleted a collection accidently, you got 1 hour's time to recover it from the delayed node;
* There must be a majority of nodes left in a set to elect a primary, that means a replica set must have at least **3 nodes**, if not a majority of nodes left, then no one can be elected as a primary, all nodes become secondary and the set becomes **read-only**;

### Start a Replica Set

```sh
# start multiple mongod with the same repl set name
#  the repl set name can be configed in a conf file as well
mongod --replSet=<replset>

# connect to one node
mongo --port <port>

# only need to initiate on one node
rs.initiate()

# create a user, otherwise you can't add nodes to the set
use admin
db.createUser({
  user: "my-user",
  pwd: "my-pass",
  roles: [
    {role: "root", db: "admin"}
  ]
})

# exit now and log back using a username
exit
```

```sh
# connecting to a replica set, which acctually connects to the primary node
mongo --host "<replset>/<ip>:<port>" -u <user> -p <pass> --authenticationDatabase 'admin'

# show status
rs.status()

# add a node
rs.add("<ip>:<port>")

# remove a node
rs.remove("<ip>:<port>")

# check
rs.isMaster()

# step down
rs.stepDown()

# show oplog data
rs.printReplicationInfo()
```

instead of adding nodes one by one, you can put them in a config file:

```js
// init_replica.js
config = { _id: "myReplSet", members:[
          { _id : 0, host : "localhost:27017"},
          { _id : 1, host : "localhost:27018"},
          { _id : 2, host : "localhost:27019"} ]
};

rs.initiate(config);
rs.status();
```

then `mongo < init_replica.js`


### reconfig a running replica set

```sh
# get current config (a JS object)
cfg = rs.conf()

# update the config: making member 3 hidden
cfg.members[3].votes = 0
cfg.members[3].hidden = true
cfg.members[3].priority = 0

# apply the updated config
rs.reconfig(cfg)
```

### `local` DB

The `local` db contains information about the repl set:

```sh
# quering oplog
use local
db.oplog.rs.find()

db.oplog.rs.stats()
```

* `oplog.rs` is a **capped** collection, which means its size is predefined (5% of available disk by default), new log entries will overwrite oldest entries when the size limit is reached;
* One operation may result in many `oplog.rs` entries, such as `updateMany` will create an entry for each affected document;
* Any data written into the `local` db is strictly local, it won't be added to oplog, won't be replicated;

### Write concern levels

Whether a client app waits for acknowledgement from the replica set:

* `0` - don't wait for acknowledgement;
* `1` - (default) wait for acknowledgement from primary only (written data may lost if the primary stops working);
* `>=2` - wait from primary and one or more secondaries;
* `majority` - wait from a majority number of nodes;

Other options:

* `wtimeout` - timeout threshold;
* `j` - whether the journal needs to be saved to disk before sending acknowledgement (default to `false`, which may result in data loss);

Usage:

```js
db.foo.insert({
    ...
}, {
    writeConcern: {
        w: 'majority',
        wtimeout: 500,
    }
});

// return something like this if timeout exceeded:

/*
WriteResult({
	"nInserted" : 1,
	"writeConcernError" : {
		"code" : 64,
		"codeName" : "WriteConcernFailed",
		"errInfo" : {
			"wtimeout" : true
		},
		"errmsg" : "waiting for replication timed out"
	}
})
*/
```

### Read concern levels

* `local`   - latest data (data may be lost if a rollback occurs);
* `available`   - the same as `local` except in sharded clusters;
* `majority` - return data present on majority number of nodes;
* `linearizable`

![MongoDB Read Concerns](images/mongo-read-concerns.png)

### Read Preference

* `primary` - always get the latest data
* `primaryPreferred`
* `secondary`
* `secondaryPreferred`
* `nearest` - good for geographically distributed system

all options except `primary` may result in stale data


## Sharding

![MongoDB Sharding and Replica Set](./images/mongo-sharding-replicaset.png)

* You can start and connect to multiple `mongos` from a client driver, the driver can failover from one to another;
* In production env, the config servers should be in a replication set as well;

### Shard key

* MongoDB use a hash function on shard key for sharding;
* MongoDB will create an index for the shard key if it doesn't exist;
* Shard key **doesn't** need to be unique;
* A unique key on a sharded collection must be the shard key itself or indexes prefixed with the shard key;
* If a shard key is not included in a query, `mongos` will go to all the shards to get the data;
* All updates should contain the shard key or `_id` field;


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
    * Equlaity on index prefix, followed by sort field:
        * `.find({ a: 20 }).sort({ b: 1 })`;
        * `.find({ a: 20, b: { $gt: 20 } }).sort({ b: 1 })`;
        * `.find({ a: 20, c: { $gt: 20 } }).sort({ b: 1 })`;
    * **NOT** used for:
        * `.find().sort({ b: 1, a: 1 })`;
        * `.find().sort({ a: 1, b: -1 })`;
        * `.find().sort({ a: -1, b: 1 })`;
        * `.find().sort({ a: 1, c: 1 })`;
        * `.find().sort({ a: 1, c: 1 })`;
        * `.find({ a: { $gt: 20 }}).sort({ b: 1 })`: `a` is a range predicate, the index can be used for filtering but not sorting;

**Equality fields first, then sort fields, then range fields**

### Multikey indexes

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

* `{'tags': 1}`: a multikey index, each element of the array is a key;
* `{'scores.class': 1}`: can be on a sub-field of documents in an array;
* `{'tags': 1, 'color': 1}` is valid;
* `{'tags': 1, 'location': 1}` is **NOT** valid, can't use two array fields in one index;

### Partial index

* Not all documents are indexed, you can just index a subset which get most of the queries, it will be more efficient, since not all documents need to be added to the index:
    ```js
    {
        ...
        cuisine: "Sichuan",
        stars: 4,
        address: {
            city: "Auckland",
            ...
        }
    }
    ```
    create a partial index on city and cuisine, but only for restaurants with ratings higher than 3.5, that will cover most queries:
    ```js
    db.restaurants.createIndex(
        { 'address.city': 1, cuisine: 1 },
        { partialFilterExpression: { 'stars': { $gte: 3.5 }}}
    );
    ```
* The filter field doesn't need to be in the index;
* The query needs to have predicates matching the filter expression:
    ```js
    db.restaurants.find({
        'address.city': 'Auckland',
        'stars': { $gte: 4 },     // needed inorder to use the index
    });
    ```
* Sparse index is a special case of partial index:
    ```js
    db.restaurants.createIndex(
        { 'stars': 1 },
        { sparse: true }
    );

    // is equivalent to
    db.restaurants.createIndex(
        { 'stars': 1 },
        { partialFilterExpression: { 'stars': { $exists: true }}}
    );
    ```

### Full text index

```js
// create a text index (on multiple fields)
db.foo.createIndex({'title': 'text', 'slogan': 'text', 'description': 'text'})

// search against the index (case insensitive)
//  not every word need to be present in the record
db.foo.find({$text: {$search: 'football dog'}})

// sort by text maching score, this makes sure the best result returns first
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

## Aggregation

### Overview

Aggregation allows you to do some data processing on the server, instead of fetching all the data and processing them in a client application.

```js
// basic aggregate structure
db.myCollection.aggregate([
    { stage1 },
    { stage2 },
    { ...stageN },
], {
    options
});

// simple example with two stages
db.solarSystem.aggregate([{
    $match: {
        meanTemperature: { $gte: -40, $lte: 40 }
    }
}, {
    $project: {
        _id: 0,
        name: 1,
        hasMoons: { $gt: [ "$numberOfMoons", 0 ] }
    }
}]);
// { "name" : "Earth", "hasMoons" : true }
```

* Field path: `"$age"`    (single `$`)
* System variable: `"$$CURRENT"`    (`$$` followed by all uppercase)
* User variable: `"$$foo"`    (`$$` followed by all lowercase)

### `$match` stage

* Use the same syntax as `find`;
* Should come early in an aggregation pipeline;

### `$project`

* Transforms data, like the `map()` function in JS;
* More powerful than projection in find, not limited to removing and retaining fields, it lets you create new fields;
* Can be used as many times as required within a pipeline;

```js
// get the count of movies with a single word title
db.movies.aggregate([
    {
        // split the "$title" field
        $project: {
            title: { $split: ["$title", " "] }
        }
    }, {
        // filter by array size
        $match: {
            title: { $size: 1 }
        }
    }
]).itcount();


// find movies which has the same name in 'directors', 'cast' and 'writers'
db.movies.aggregate([
    {
        // make sure each field is a non empty array
        $match: {
            cast: { $elemMatch: { $exists: true } },
            directors: { $elemMatch: { $exists: true } },
            writers: { $elemMatch: { $exists: true } }
        }
    }, {
        // process writers array, convert 'George Lucas (story)' to 'George Lucas'
        $project: {
            cast: 1,
            directors: 1,
            writers: {
                $map: {
                    input: "$writers",
                    as: "writer",
                    in: {
                        $arrayElemAt: [
                            {
                                $split: [ "$$writer", " (" ]
                            },
                            0
                        ]
                    }
                }
            }
        }
    }, {
        // get the $size of array intersection
        $project: {
            common_count: {
                $size: {
                    $setIntersection: [
                        "$cast",
                        "$directors",
                        "$writers",
                    ]
                }
            }
        }
    }, {
        // count >= 1
        $match: {
            common_count: { $gte: 1 }
        }
    }
]).itcount();
```

### `$addField`

Transform or add new fields;

### `$geoNear`

* Filter by geo distance;
* Must be first stage;

### cusor-like stages

* `$skip`;
* `$limit`;
* `$count`;
    ```js
    db.people.aggregate([
        {
            $match: {
                age: 18
            }
        }, {
            // give the $count a label
            $count: "People Interested"
        }
    ]);
    ```
* `$sort`;

    * Can use indexes if used early in a pipeline;
    * Use up to 100MB of RAM by default, option `allowDisUse: true` can be set for larger sorts;

### `$sample`

Get a random set of documents

```js

db.people.aggregate([
    {
        ...
    }, {
        $sample: 20
    }
]);
```

### `$group`

* Similar to `GROUP` in SQL;
* Use the specified `_id` field as the group key;
* You can use accumulator expressions to work on a group of documents: `$sum`, `$avg`, `$first`, `$last`, `$min`, `$max`, `$push`, `$addToSet`, ...;

```js
// get a list of company names founded in each year
db.companies.aggregate([
    {
        $match: {
            founded_year: { $ne: null }
        }
    }, {
        $group: {
            "_id": { 'founded_year': "$founded_year" },
            "companies": { $push: "$name" }
        }
    }, {
        $sort: { "_id.founded_year": 1 }
    }
]);

/*
{ "_id" : { "founded_year" : 1800 }, "companies" : [ "Alstrasoft", "SmallWorlds", "US Army" ] }
{ "_id" : { "founded_year" : 1802 }, "companies" : [ "DuPont" ] }
{ "_id" : { "founded_year" : 1833 }, "companies" : [ "McKesson", "Bachmann Industries" ] }
{ "_id" : { "founded_year" : 1835 }, "companies" : [ "Bertelsmann" ] }
...
*/

// calculate fund raised in each year
db.companies.aggregate([
    {
        $match: {
            funding_rounds: { $exists: true, $ne: null }
        }
    }, {
        // unwind the funding_rounds array of each doc
        $unwind: "$funding_rounds"
    }, {
        // $sum up the raised_amount
        $group: {
            "_id": { 'funded_year': "$funding_rounds.funded_year" },
            "total_raised": { $sum: "$funding_rounds.raised_amount" }
        }
    }, {
        $sort: { "total_raised": -1 }
    }
]);
/*
{ "_id" : { "funded_year" : 2008 }, "total_raised" : NumberLong("27249115703") }
{ "_id" : { "funded_year" : 2011 }, "total_raised" : NumberLong("19879268599") }
{ "_id" : { "funded_year" : 2009 }, "total_raised" : 19082672825.1 }
*/
```



```js
db.companies.aggregate([
    {$match: {
        founded_year: 2004
    }},
    {$project: {
        name: 1,
        funding_rounds: 1,
        roundsCount: {$size: "$funding_rounds"}
    }},
    {$match: {
        roundsCount: {$gte: 5}
    }},
]);
db.companies.aggregate([
    {$match: {
        founded_year: 2004
    }},
    {$project: {
        name: 1,
        funding_rounds: 1,
        roundsCount: {$size: "$funding_rounds"}
    }},
    {$match: {
        roundsCount: {$gte: 5}
    }},
    {$addFields: {
        avg_amount: {$avg: "$funding_rounds.raised_amount"}
    }},
    {$project: {
        funding_rounds: 0,
    }},
    {$sort: {avg_amount: 1}}
]);
```



