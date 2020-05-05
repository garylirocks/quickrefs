# Express

- [Barebone Express app](#barebone-express-app)
- [Middleware pattern](#middleware-pattern)
- [Request](#request)
  - [Params and Queries](#params-and-queries)
  - [Param callbacks](#param-callbacks)
- [Static files](#static-files)
- [Error Handling](#error-handling)
- [Sub app](#sub-app)
- [Router](#router)

## Barebone Express app

```js
var express = require("express"),
  app = express();

app.get("/", function(req, res) {
  res.send("Hello World");
});

app.use(function(req, res) {
  res.sendStatus(404);
});

var server = app.listen(3000, function() {
  var port = server.address().port;
  console.log("Express server listening on port %s", port);
});
```

## Middleware pattern

![Express Middleware](images/express_middleware.png)

```js
var express = require("express");
var app = express();

var myLogger = function(req, res, next) {
  console.log("LOGGED");
  next();
};

app.use(myLogger);

app.get("/", function(req, res) {
  res.send("Hello World!");
});

app.listen(3000);
```

A middleware:

- Can modify the `req` and `res` objects;
- Passes control to next middleware by calling `next`;
- Can end the request-response cycle;
- Order matters, in the example above: `myLogger` is executed before the root route;

Route matching:

  - In `app.use`, the `path` is a prefix, default to `/`, so a route like `/foo` will match any paths like `/foo/bar`, `/foo/bar/blah`, so `/` matches every request;
  - But in `app.METHOD`, the `path` matches the whole path, so a route like `/foo` will match only `/foo` or `/foo/`;


You can use `app.route` to attach multiple HTTP verb handlers to a route, avoiding duplicate route names:

```js
var app = express()

app.route('/events')
  .all(function (req, res, next) {
    // runs for all HTTP verbs first
    // think of it as route specific middleware!
  })
  .get(function (req, res, next) {
    res.json({})
  })
  .post(function (req, res, next) {
    // maybe add a new event...
  })
```


## Request

### Params and Queries

```js
/* GET */
app.get("/:name", function(req, res, next) {
  var name = req.parmas.name; // get the name parameter
  var queries = req.queries; // all GET queries
  // ...
});

/* POST */
app.use(express.bodyParser()); // add a middleware, it makes req.body available
app.post("/", function(req, res, next) {
  var postData = req.body; // get all the post data
  // ...
});
```

### Param callbacks

Use `app.param` to add a call back for request parameters:

```js
app.param('id', function (req, res, next, id) {
  console.log('CALLED ONLY ONCE')
  next()
})

app.get('/user/:id', function (req, res, next) {
  console.log('although this matches')
  next()
})

app.get('/user/:id', function (req, res) {
  console.log('and this matches too')
  res.end()
})
```

On `GET /user/42`, the following is printed:

```
CALLED ONLY ONCE
although this matches
and this matches too
```

- The param callback is called only once, even multiple routes has the same parameter;
- It is called before the route handler;


## Static files

- Serve static content for the app from the `public` directory in the application directory, the request path doesn't need to be prefixed with `/public`:

  ```js
  // GET /style.css etc
  app.use(express.static(path.join(__dirname, 'public')))
  ```

- Mount the middleware at `/static` to serve static content only when their request path is prefixed with `/static`:

  ```js
  // GET /static/style.css etc.
  app.use('/static', express.static(path.join(__dirname, 'public')))
  ```

- Disable logging for static content requests by loading the logger middleware after the static middleware:

  ```js
  app.use(express.static(path.join(__dirname, 'public')))
  app.use(logger())
  ```

- Serve static files from multiple directories, but give precedence to `./public` over the others:

  ```js
  app.use(express.static(path.join(__dirname, 'public')))
  app.use(express.static(path.join(__dirname, 'uploads')))
  ```



## Error Handling

```js
app.use(function (err, req, res, next) {
  console.error(err.stack)
  res.status(500).send('Something broke!')
})
```

- You must specify four parameters for an error handling middleware;


## Sub app

You can have a separate express app to handle only a paticular route, in this example, we have an `admin` app handling the `/admin` route.

```js
var express = require('express')

var app = express() // the main app
var admin = express() // the sub app

admin.get('/', function (req, res) {
  console.log(admin.mountpath) // /admin
  res.send('Admin Homepage')
})

app.use('/admin', admin) // mount the sub app
```

## Router

A `router` object is an isolated instance of middleware and routes, it's like a "mini-application";

- Every express app has a built-in app router;
- You can create a new router by `express.Router()`;
- And it can be used just as a middleware by an app or another router: `app.use(router)`, `router.use(anotherRouter)`;
- In practice: you can use a router for a particular root URL, in this way separating your routes into files or even mini-apps;

```js
const router = express.Router();

// invoked for any requests passed to this router
router.use(function (req, res, next) {
  // .. some logic here .. like any other middleware
  next()
})

// `/calendar/events` matches this route
router.get('/events', function (req, res, next) {
  // ..
})

// only requests to /calendar/* will be sent to our "router"
app.use('/calendar', router)
```
