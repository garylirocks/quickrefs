GraphQL
==========

- [Why](#why)
- [Schema Definition Language (SDL)](#schema-definition-language-sdl)
  - [Fields](#fields)
  - [Query](#query)
  - [Variables](#variables)
  - [Directives](#directives)
  - [Aliases](#aliases)
  - [Fragments](#fragments)
  - [Inline Fragments](#inline-fragments)
  - [Mutation](#mutation)
  - [Subscriptions](#subscriptions)


## Why

* Return just what is required in the client, avoid underfetching and overfetching;
* One endpoint, allows rapid front-end iterations (no need to wait for endpoints being added/modified);


## Schema Definition Language (SDL)

```graphql
// operations: Query, Mutation, Subscription
type Query {
    allPersons(last: Int): [Person!]!
    allPosts(last: Int): [Post!]!
}

type Mutation {
    createPerson(name: String!, age: Int!): Person!
    updatePerson(id: ID!, name: String!, age: Int!): Person!
    deletePerson(id: ID!): Person!
    createPost(title: String!): Post!
    updatePost(id: ID!, title: String!): Post!
    deletePost(id: ID!): Post!
}

type Subscription {
    newPerson: Person!
    updatedPerson: Person!
    deletedPerson: Person!
    newPost: Post!
    updatedPost: Post!
    deletedPost: Post!
}

// actual entities: one to many relation between Person and Post
type Person {
    name: String!
    age: Int!
    posts: [Post!]!
}

type Post {
    title: String!
    author: Person!
}
```

* `!` indicates a required field;
* `[Foo]` a list of `Foo`;

### Fields

* A field can be of a scalar or composite type;
    * Scalar types include: `Int`, `Float`, `String`, `Boolean`;
    * A composite type:
        ```graphql
        type Post {
            title: String!
            author: Person!
        }
        ```

### Query

Last 2 persons, getting `name` and `age`:

```graphql
{
    allPerson(last: 2) {
        name
        age
    }
}

# it's a good practice to add in operation type and name
query GetLatestTwoPersons {
    allPerson(last: 2) {
        name
        age
    }
}
```

### Variables

```graphql
query GetLatestPersons($count: Int!) {
    allPerson(last: $count) {
        name
        age
    }
}
```

```graphql
{
    "count": 2
}
```

### Directives

```graphql
query GetLatestPersons(
    $count: Int!,
    $includeAge: Boolean!
) {
    allPerson(last: $count) {
        name
        age @include(if: $includeAge)
    }
}
```

```graphql
{
    "count": 2,
    "includeAge": true
}
```

Another common directive is `@skip`, the logic is inversed.

### Aliases

```graphql
query GetLatestTwoPersons {
    allPerson(last: 2) {
        fullname: name          # use 'fullname' as an alias of 'name'
        age
    }
}

# you can have multiple aliases for the same field/query
query GetLatestPersons {
    last2: allPerson(last: 2) {
        name
        age
    }

    last3: allPerson(last: 3) {
        name
        age
    }
}
```

### Fragments

```graphql
query GetLatestPersons {
    last2: allPerson(last: 2) {
        ...PersonInfo
    }

    last3: allPerson(last: 3) {
        ...PersonInfo
    }
}

fragment PersonInfo on Person {
    name
    age
}
```

### Inline Fragments

```graphql
query GetShapes {
    shape {
        ... on Circle {
            radius
        }
        ... on Rectangular {
            width
            length
        }
    }
}
```

Here `shape` has a union type: either a `Circle` or a `Rectangular`


### Mutation

* All mutation queries starts with the `mutation` keyword;
* Allows you to mutate and query with the same query;

```graphql
mutation {
    createPerson(name: "Bob", age: 36) {
        name
        age
    }
}
```

### Subscriptions

```graphql
subscription {
    newPerson {
        name
        age
    }
}
```
