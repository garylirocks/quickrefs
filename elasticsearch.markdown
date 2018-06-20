ElasticSearch
==============

## Core concepts

![Elasticsearch storage structure](images/elasticsearch_storage_structure.png)

* Cluster 
    
    a collection of nodes which share the same cluster name, each cluster has a single master node;

* Node

    * a ElasticSearch server (can be a docker container);
    * multiple nodes can be started on a single server for testing, but usually you should have one node per server;

* Index

    * like a *table* in a relational DB;
    * a collection of documents that have somewhat similar characteristics, you can have an index for customer data, another index for a product catalog, etc;
    * you can define as many indexes as you want in a cluster;
    * it is a logical namespace which maps to one or more primary shards and can have zero or more replica shards;
        
* Analysis

    * the process of converting full text to terms, e.g. from 'Foo-Bar' to terms `foo` and `bar`;
    * it happens at both index and search time;

* Document

    * a JSON document which is stored in Elasticsearch, it is like a row in a table in a relational DB;
    * each document is stored in an `index` and has a `type` and an `id`;
    * the original JSON document that is indexed will be stored in the `_source` field, which is returned by default when getting or searching for a document;

* Id

    identifies a document, it must be unique, if no ID provided, then it will be auto-generated;

* Field

    * a document contains a list of fields, the value can be a scalar value or a nested structure; 
    * the mapping for each field has a field *type* (eg `integer`, `string`, `object`);
    * the mapping also allows you to define how the value for a field should be analyzed;

* Filter

    * a filter is a non-scoring query, it does not score documents;
    * it is only concerned whether a document matches or not;
    * in most cases, the goal of filtering is to reduce the number of documents that have to be examined;

* Mapping

    * like a *schema definition* in a relational DB;
    * each index has a mapping, which defines a type, and a number of index-wide settings;
    * can be defined explicitly, or it will be generated automatically when a document is indexed;

* Primary shard

    * by default, each index has 5 primary shards;

* Query

    * basic component of a search;
    * a search can be defined by one or more queries;
    * in general, use query clause for full-text search or for any condition that requires scoring, use filters for everything else;

* Term

    * a term is an exact value that is indexed in Elasticsearch;
    * `foo`, `Foo`, `FOO` are not equivalent;

* Text

    * is ordinary unstructured text;
    * will be analyzed into terms;

* Type

    * used to represent the *type* of documents, e.g. an *email*, a *user*, or a *tweet*;
    * Types are deprecated now;
    * Indices created in Elasticsearch 6.0 or later may only contain a single mapping type;
    * Previously in a `twitter` index, you can have a `user` type and a `tweet` type, now you should create two separate indices, one `user` index and one `tweet` index;








    






