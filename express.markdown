Express
=============

- [Barebone Express app](#barebone-express-app)
- [Request](#request)
    - [Params and Queries](#params-and-queries)

## Barebone Express app

```js
var express = require('express'),
    app = express();

app.get('/', function(req, res){
    res.send('Hello World');
});

app.use(function(req, res){
    res.sendStatus(404); 
});

var server = app.listen(3000, function() {
    var port = server.address().port;
    console.log('Express server listening on port %s', port);
});
```

## Request 

### Params and Queries

```js
/* GET */
app.get('/:name', function(req, res, next) {
    var name = req.parmas.name;         // get the name parameter
    var queries = req.queries;          // all GET queries
    // ...
});


/* POST */
app.use(express.bodyParser());          // add a middleware, it makes req.body available
app.post('/', function(req, res, next) {
    var postData = req.body;         // get all the post data
    // ...
});
```