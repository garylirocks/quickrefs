MongoDB
========

[SQL to MongoDB Mapping Chart](https://docs.mongodb.com/manual/reference/sql-comparison/)

## Connection / Management

```bash
show dbs            # list all dbs
use <db>            # switch to a db

show tables         # show tables in current db
```

## CRUD

* `db`: current database
* `users`: a collection

### Create

the object in `insertOnce` is a document

```bash
db.users.insertOne(
    {
        name: "gary",
        age: 20
    }
)
```

### Read

```
> db.users.find()
{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 20 }

> db.users.find( 
    { age: {$gt: 18} },     # query criteria
    {name: 1}               # projection, only get 'name' field
)

{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary" }
```

### Update

```
> db.users.updateOne(
... { name: {$eq: "gary"} },
... { $set: {age: 30} }
... )
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

> db.users.find()
{ "_id" : ObjectId("59f9018840bf58d73f217a51"), "name" : "gary", "age" : 30 }
```

### Delete

```
> db.users.deleteOne(
... {age: {$gt: 20}}
... )
{ "acknowledged" : true, "deletedCount" : 1 }

> db.users.find()
> 
```
