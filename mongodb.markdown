MongoDB
========

- [MongoDB](#mongodb)
    - [Concepts](#concepts)
        - [Field](#field)
    - [Architecture](#architecture)
    - [Connection / Management](#connection--management)
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
show dbs            # list all dbs
use <db>            # switch to a db

show tables         # show tables in current db

db.users.drop()     # drop/delete the users table
```

## CRUD

* `db`: current database
* `users`: a collection

### Create

the object in `insertOnce` is a document

```sh
db.users.insertOne(
    {
        name: "gary",
        age: 20
    }
)
```

### Read

```sh
> db.users.find()
{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 20 }

> db.users.find( 
    { age: {$gt: 18} },     # query criteria
    {name: 1}               # projection, only get 'name' field
)

{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary" }
```

### Update

```sh
> db.users.updateOne(
... { name: {$eq: "gary"} },
... { $set: {age: 30} }
... )
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

> db.users.find()
{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 30 }
```

### Delete

```sh
> db.users.deleteOne(
... {age: {$gt: 20}}
... )
{ "acknowledged" : true, "deletedCount" : 1 }

> db.users.find()
> 
```
