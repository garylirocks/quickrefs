# NodeJS notes

- [Basic concepts](#basic-concepts)
  - [Node dependencies](#node-dependencies)
- [Blocking vs non-blocking](#blocking-vs-non-blocking)
  - [What is blocking ?](#what-is-blocking-)
  - [Concurrency](#concurrency)
- [Event loop](#event-loop)
  - [Thread pool](#thread-pool)
  - [Phases](#phases)
    - [timers](#timers)
    - [pending](#pending)
    - [idle, prepare](#idle-prepare)
    - [poll](#poll)
    - [check](#check)
    - [close callbacks](#close-callbacks)
  - [`setImmediate` vs `setTimeout`](#setimmediate-vs-settimeout)
  - [`process.nextTick`](#processnexttick)
    - [What is it for ?](#what-is-it-for-)
    - [`process.nextTick()` vs `setImmediate()`](#processnexttick-vs-setimmediate)
    - [Example](#example)
  - [Don't block the Event Loop](#dont-block-the-event-loop)
- [Streams and pipes](#streams-and-pipes)
  - [read](#read)
  - [write](#write)
  - [pipe](#pipe)
  - [events](#events)
- [Module System](#module-system)
  - [Resolving: `module.paths`, `module.resolve`](#resolving-modulepaths-moduleresolve)
  - [Parent-child relation: `module.parent`, `module.children`](#parent-child-relation-moduleparent-modulechildren)
  - [`module.loaded`](#moduleloaded)
  - [`exports`, `module.exports`](#exports-moduleexports)
  - [Synchronicity](#synchronicity)
  - [Circular dependency](#circular-dependency)
  - [JSON and C/C++ Addons](#json-and-cc-addons)
  - [Module Wrapping](#module-wrapping)
  - [The `require` object](#the-require-object)
  - [Module Caching](#module-caching)
  - [ECMAScript Modules in Node 11](#ecmascript-modules-in-node-11)
    - [Enabling](#enabling)
    - [Features](#features)
    - [Differences between `import` and `require`](#differences-between-import-and-require)
  - [CommonJs vs. ES6 Modules](#commonjs-vs-es6-modules)
- [Error Handling](#error-handling)
  - [Operational errors vs. programmer errors](#operational-errors-vs-programmer-errors)
  - [Handling operational errors](#handling-operational-errors)
  - [Programmer errors](#programmer-errors)
- [Debugging](#debugging)
  - [Command line debugging](#command-line-debugging)
  - [Remote debugging](#remote-debugging)
- [Barebone HTTP server](#barebone-http-server)
- [CLI](#cli)
  - [Limit memory usage](#limit-memory-usage)
- [Tools](#tools)
  - [`nvm` - manage multiple versions of Node](#nvm---manage-multiple-versions-of-node)
  - [NPM](#npm)
    - [`package.json`](#packagejson)
    - [Avoid installing packages globally](#avoid-installing-packages-globally)
    - [Publish package to NPM](#publish-package-to-npm)
    - [Symlink a package folder](#symlink-a-package-folder)
  - [Yarn](#yarn)

## Basic concepts

### Node dependencies

Libs:

- V8 - JS engine, Node controls it via V8 C++ API;
- libuv - a C library that provides a consistent interface for non-blocking I/O operations(e.g. file system, network, DNS, child processes, pipes, signal handling, polling, streaming) across all supported platforms;
- http-parser - lightweight C lib for HTTP parsing;
- c-ares - for some async DNS requests;
- OpenSSL - `tls` and `crypto`;
- zlib - compressions and decompression;

Tools: npm, gyp, gtest

## Blocking vs non-blocking

### What is blocking ?

- It happens when a Node process can not continue JavaScript execution until a **non-JavaScript operation**(such as I/O) completes;

  ```js
  const fs = require('fs');
  const data = fs.readFileSync('/file.md'); // blocks here until file is read
  moreWork();
  ```

- Most commonly blocking operations are synchronous methods from the Node standard library that use libuv, native modules may also have blocking methods;

- **CPU intensive JS operations** are not typically referred to as blocking;

- All of the I/O methods in the Node standard library provide asynchronous versions, which are **non-blocking**, and accept callback functions. Some methods also have **blocking** counterparts, which have names that end with `Sync`;

### Concurrency

- JavaScript execution in Node is **single threaded**, so concurrency refers to the event loop's capacity to execute JavaScript call back functions after completing other work;

- Other languages may create additional threads to handle concurrent work;

## Event loop

[Morning Keynote- Everything You Need to Know About Node.js Event Loop - Bert Belder, IBM][bert-belder]\
[Daniel Khan - Everything I thought I knew about the event loop was wrong][daniel-khan]\
[Further Adventures of the Event Loop - Erin Zimmer - JSConf EU 2018][erin-zimmer]\
[NodeJS Event Loop Series][deepal-jayasekara]

Event loop is what allows Node.js to perform non-blocking I/O operations by offloading operations to the system kernel whenever possible.\
When Node.js starts, it
  1. initializes the event loop,
  2. processes the input script (which may make async API calls, schedule timers, etc.),
  3. then begins processing the event loop.

Notes:

- Event loop is implemented in **libuv**.
- There is **only one thread** that executes JavaScript code and this is the thread **where the event loop** is running
- Libuv creates a pool with four threads that is **only used if no asynchronous API is available**
- Event loop is **NOT** a stack or queue, it's a **set of phases** with dedicated data structures for each phase

Libuv architecture:
![Libuv architecture](images/node_libuv-architecture.png)

Where libuv sits in whole Node.js architecture:
![Node.js architecture](images/node_architecture.png)


Pseudo code (*Node only, different from browser*)

```js
while (tasksAreWaiting()) {
  queue = getNextQueue();

  while (queue.hasTasks()) { // run all tasks in a queue
    task = queue.pop();
    execute(task);

    while (nextTickQueue.hasTasks) { // run to exhaustion, higher priority than promiseQueue
      doNextTickTask();
    }

    while (promiseQueue.hasTasks) { // run to exhaustion
      doPromiseTask();
    }
  }
}
```

### Thread pool

Thread pool handles I/O tasks which OS does not provide a non-blocking version, as well as some CPU-intensive tasks

1. I/O-intensive

  - DNS: `dns.lookup()`, `dns.lookupService()`
  - File system: All file system APIs except `fs.FSWatcher()` and those that are explicitly synchronous

2. CPU-intensive

  - Crypto: `crypto.pbkdf2()`, `crypto.scrypt()`, `crypto.randomBytes()`, `crypto.randomFill()`, `crypto.generateKeyPair()`
  - Zlib: All except those explicitly synchronous ones

The Worker Pool uses a queue whose entries are tasks to be processed. A Worker pops a task from this queue and works on it, and when finished the Worker raises an "At least one task is finished" event for the Event Loop.

### Phases

Event loop is implemented in phases, the following is a simplified overview:

```
   ┌───────────────────────────┐
┌─>│           timers          │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │     pending callbacks     │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │       idle, prepare       │
│  └─────────────┬─────────────┘      ┌───────────────┐
│  ┌─────────────┴─────────────┐      │   incoming:   │
│  │           poll            │<─────┤  connections, │
│  └─────────────┬─────────────┘      │   data, etc.  │
│  ┌─────────────┴─────────────┐      └───────────────┘
│  │           check           │
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
└──┤      close callbacks      │
   └───────────────────────────┘
```

- Each phase has a FIFO queue of callbacks to execute
- In each phase, event loop will execute callbacks in that phases's queue until the queue has been exhausted or the maximum number of callbacks has executed

#### timers

This phase executes callbacks scheduled by `setTimeout()` and `setInterval()`

- The queue in timer phase is actually a heap (priority queue), a data structure which allows you to get the min or max value in constant time;
- The timeout value you set is just a minimal timeout value, the event is not guaranteed to run at the exact time;
- Node.js caps minimum timeout to **1ms**, so even if you set a `0ms` delay, it is actually overridden to `1ms`.

#### pending

Executes callbacks for some system operations such as types of TCP errors. For example, a TCP socket received `ECONNREFUSED` when attempting to connect.

#### idle, prepare

Only used internally

#### poll

Two main functions:
  1. Calculating how long it should block and poll for I/O, then

  Simplified logic: If there is any task in other phases, timeout would be 0, if there is any timer set, it would be the remaining time for the closest timer, otherwise it would be indefinite

  2. Processing events in the **poll** queue

#### check

`setImmediate()` callbacks

#### close callbacks

some close callbacks, e.g. `socket.on('close', ...)`


### `setImmediate` vs `setTimeout`

When they are not set within an I/O cycle (i.e. the main module), then the order is not determinstic, it is bound by the performance of the process

```js
// timeout_vs_immediate.js
setTimeout(() => {
  console.log('timeout');
}, 0);

setImmediate(() => {
  console.log('immediate');
});
```

```sh
$ node timeout_vs_immediate.js
timeout
immediate

$ node timeout_vs_immediate.js
immediate
timeout
```

However, if they are within an I/O cycle, the immediate callback is always executed first:

```js
// timeout_vs_immediate.js
const fs = require('fs');

fs.readFile(__filename, () => {
  setTimeout(() => {
    console.log('timeout');
  }, 0);
  setImmediate(() => {
    console.log('immediate');
  });
});
```

### `process.nextTick`

- It's not technically part of the event loop.
- The `nextTickQueue` will be processed after the current operation is completed, regardless of the current phase of the event loop.
- `nextTickQueue` is executed until exhaustion, so avoid calling `process.nextTick` recursively.

#### What is it for ?

It makes an API call asynchronous even where it doesn't have to be.

```js
let bar;

// this has an asynchronous signature, but calls callback synchronously
function someAsyncApiCall(callback) { callback(); }

// the callback is called before `someAsyncApiCall` completes.
someAsyncApiCall(() => {
  // since someAsyncApiCall hasn't completed, bar hasn't been assigned any value
  console.log('bar', bar); // undefined
});

bar = 1;
```

It's better to change it to:

```js
let bar;

function someAsyncApiCall(callback) {
  process.nextTick(callback);
}

someAsyncApiCall(() => {
  console.log('bar', bar); // 1
});

bar = 1;
```

#### `process.nextTick()` vs `setImmediate()`

- `process.nextTick()` fires immediately on the same phase
- `setImmediate()` fires on the following iteration or 'tick' of the event loop

They are named badly, `process.nextTick()` fires more immediately than `setImmediate()`

**Most of the time you only need `setImmediate()`**

#### Example

```js
const foo = () => {
  console.log('in timeout');

  setTimeout(() => console.log('in nested timeout'));

  process.nextTick(() => {
    console.log('in nextTick');
    process.nextTick(() => {console.log('in nested nextTick')});
  });
}

setTimeout(foo);
setTimeout(foo);

// in timeout
// in nextTick
// in nested nextTick
// in timeout
// in nextTick
// in nested nextTick
// in nested timeout
// in nested timeout
```

- nextTick tasks get run immediately when current task is done, even though there may have more tasks in the current task queue;
- newly scheduled zero-delay timeout needs to wait for next loop;


### Don't block the Event Loop

In Apache, there is a thread for each client, when one thread blocks, the OS will interrupt it and run another one.

Node.js handles many clients with few threads, if a thread blocks handling one client's request, then pending client requests may not get a turn until the thread finishes its callback or task. This means you **shouldn't do too much work for any client in a single callback or task**.

Some operations are slow, and would potentially block the Event Loop:

- REDOS: Regular Expression Denial of Service (regexp that requires O(2^n) time), see [REDOS](https://nodejs.org/en/docs/guides/dont-block-the-event-loop/#blocking-the-event-loop-redos) for details and solutions
- Synchronous APIs from some core modules (fs, crypto, zlib, child_process), they are intended for scripting convenience, not intended for use in the server context.
- JSON DOS, it's slow to process large amount of data with `JSON.parse` and `JSON.stringify`

## Streams and pipes

Node makes extensive use of streams, there are fundamental stream types in Node:

- **Readable**: such as `fs.createReadStream`;
- **Writable**: such as `fs.createWriteStream`;
- **Duplex**: both readable and writable, such as a TCP socket;
- **Transform**: a duplex stream that can be used to modify or transfer the data, such as `zlib.createGzip`;

all streams are instances of `EventEmitter`, they emit events that can be used to read and write data, however, we can consume streams data in a simpler way using the `pipe` method

```node
readableSrc.pipe(writableDest);
```

or

```node
readableSrc
  .pipe(transformStream1)
  .pipe(transformStream2)
  .pipe(finalWrtitableDest);
```

it's recommended to use either the `pipe` method or consume streams with events, but don't mix them

### read

```node
var fs = require('fs');
var stream;
stream = fs.createReadStream('/data/test.txt');

stream.on('data', function(data) {
  var chunk = data.toString();
  console.log(chunk);
});
```

### write

```node
var fs = require('fs');
var stream;
stream = fs.createWriteStream('/data/test.txt');

stream.write('Node.js');
stream.write('Hello World');
```

### pipe

```node
var fs = require('fs');

var readStream = fs.createReadStream('/data/input.txt');
var writeStream = fs.createwriteStream('/data/output.txt');

readStream.pipe(writeStream);
```

or server a large file

```node
const fs = require('fs');
const server = require('http').createServer();

server.on('request', (req, res) => {
  const src = fs.createReadStream('./big.file');
  src.pipe(res);
});

server.listen(8000);
```

### events

```node
var events = require('events');

var eventEmitter = new events.EventEmitter();

// add a listener
eventEmitter.on('data_received', function() {
  console.log('data received succesfully.');
});

// trigger an event
eventEmitter.emit('data_received');
```

## Module System

[Medium - Samer Buna - Requiring modules in Node.js: Everything you need to know](https://medium.freecodecamp.org/requiring-modules-in-node-js-everything-you-need-to-know-e7fbd119be8)

- Node modules have a one-to-one relation with files;
- A module can be put into a directory with a `package.json` file, such as packages from NPM;
- Requiring a module means laoding the content of a file into memory;
- Node uses two modules: `require` and `module` to mnanage module dependencies;
- The main object exported by `require` module is the `require` function;
- When `require()` is invoked, Node goes thru the following sequence of steps:
  - **Resolving**: find the absolute path;
  - **Loading**: determine the type of the file content;
  - **Wrapping**: give the file its private scope, this makes both `require` and `module` local to every file we require;
  - **Evaluating**;
  - **Caching**;

### Resolving: `module.paths`, `module.resolve`

```js
// without a path
require('mod-a');

// with a relative path
require('./mod-a');

// with an absolute path
require('/lib/mod-a');

// a builtin module
require('http');
```

- When you require a module without a path, Node searchs all paths in `module.paths` in order (builtin modules always take precedence):

  ```sh
  ➜  learn-node node
  > module.paths
  [ '/home/gary/code/learn-node/repl/node_modules',
    '/home/gary/code/learn-node/node_modules',
    '/home/gary/code/node_modules',
    '/home/gary/node_modules',
    '/home/node_modules',
    '/node_modules',
    '/home/gary/.node_modules',
    '/home/gary/.node_libraries',
    '/home/gary/.nvm/versions/node/v10.6.0/lib/node' ]
  ```

- If `mod-a` is a folder, it will resolve to `mod-a/index.js` by default, but you can specify another file in `mod-a/package.json`:

  ```js
  {
    "name": "mod-a",
    "main": "start.js",  // resolve to this file
    ...
  }
  ```

- **`require.resolve`** can be used to get the full path of a module, it only does the resolving step, doesn't actually load the file, can be used to check whether a package is installed or not:

  ```sh
  > require.resolve('./mod-a')
  '/home/gary/code/learn-node/mod-a.js'
  ```

  If `mod-a` is a package in `./node_modules/` and its main file is `start.js`:

  ```sh
  > require.resolve('mod-a')
  '/home/gary/code/learn-node/node_modules/mod-a/start.js'
  ```

  Doesn't show a full path for a builtin module:

  ```sh
  > require.resolve('http')
  'http'
  ```

### Parent-child relation: `module.parent`, `module.children`

```js
// main.js
require('./mod-a');
console.log(module);
```

```js
// mod-a.js
// empty
```

```sh
➜  learn-node node main.js
Module {
  id: '.',
  exports: {},
  parent: undefined,
  filename: '/home/gary/code/learn-node/main.js',
  loaded: false,
  children:
   [ Module {
       id: '/home/gary/code/learn-node/mod-a.js',
       exports: {},
       parent: [Circular],
       filename: '/home/gary/code/learn-node/mod-a.js',
       loaded: true,
       children: [],
       paths: [Array] } ],
  paths:
   [ ... ] }
```

- `mod-a.js` is a child of `main.js`;
- `module.id` of the entry file is '.', of any other module is its full path;

### `module.loaded`

```js
// main.js
console.log(`Sync: ${module.loaded}`);
setImmediate(() => console.log(`Next tick: ${module.loaded}`));
```

```sh
➜  learn-node node main.js
Sync: false
Next tick: true
```

The value of `module.loaded` is `false` while the module is being loaded, and becomes `true` after been loaded.

### `exports`, `module.exports`

Add attributes to exports:

```js
// main.js
exports.id = 20;
exports.foo = a => a * 2;

module.exports.NAME = 'gary';
```

```sh
> require('./main.js')
{ id: 20, foo: [Function], NAME: 'gary' }
```

`exports` is an alias of `module.exports`, if you assign a new object to `exports`, it doesn't work, but you can assign a new object to `module.exports`.

```js
// main.js

// !DON'T DO THIS
exports = {
  id: 20
};

// DO IT THIS WAY
module.exports = { NAME: 'gary' };
```

```sh
> require('./main.js')
{ NAME: 'gary' }
```

So, the best practice is either using `exports` to add attributes one by one throughout the file or using `module.exports` at the end of a file.

### Synchronicity

```js
// main.js
module.exports = { id: 20 };

// !DON'T DO THIS
setImmediate(() => {
  module.exports = { name: 'gary' };
});
```

```sh
> require('./main.js')
{ id: 20 }

> require('./main.js')
{ name: 'gary' }
```

First `require` gives you the synchronous export, which gets changed later, but you **SHOULD NOT** change a module's exports asynchronously.

### Circular dependency

Let's create two files which require each other:

```js
// mod-a.js
console.log('mod-a loading starts');
exports.id = 1;

const modB = require('./mod-b');
console.log('modB in mod-a:', modB);

exports.name = 'gary';
console.log('mod-a loaded');
```

```js
// mod-b.js
console.log('mod-b loading starts');
exports.id = 2;

// Loading a partially loaded module here
const modA = require('./mod-a');
console.log('modA in mod-b:', modA);

exports.name = 'Arya';
console.log('mod-b loaded');
```

```sh
➜  learn-node node mod-a.js
mod-a loading starts
mod-b loading starts
modA in mod-b: { id: 1 }
mod-b loaded
modB in mod-a: { id: 2, name: 'Arya' }
mod-a loaded
```

We starts with `mod-a`, it requires `mod-b`, when `mod-b` requires `mod-a`, `mod-a` is partially loaded, so the partial exports are returned.

So the take away here is you can require a module before it's fully loaded, and you'll just get partial exports.

### JSON and C/C++ Addons

```sh
> require.extensions
{ '.js': [Function],
  '.json': [Function],
  '.node': [Function],
  '.mjs': [Function] }

> require.extensions['.json'].toString()
'function(module, filename) {\n  var content = fs.readFileSync(filename, \'utf8\');\n  try {\n    module.exports = JSON.parse(stripBOM(content));\n  } catch (err) {\n    err.message = filename + \': \' + err.message;\n    throw err;\n  }\n}'
```

- You can get a list of supported extensions of Node in `require.extensions`, if you don't specify a file extension, Node will try to resolve it as a `.js` file, then a `.json` file, then a binary `.node` file;
- Node reads a `.json` file's content as a string, and try to parse it with `JSON.parse`;
- You can use the `node-gyp` package to compile and build a `.cc` file into a `.node` addon file;

### Module Wrapping

In Node, a module's code is executed in a function scope, we can inspect this wrapper function like this:

```sh
> require('module').wrapper
[ '(function (exports, require, module, __filename, __dirname) { ',
  '\n});' ]
```

`require('module').wrap` is a function:

```js
function(script) {
  return Module.wrapper[0] + script + Module.wrapper[1];
}
```

This is why we have access to `exports`, `require`, `module`, `__filename` and `__diranme` in a module.

- `exports` is a reference to `module.exports`;
- `require` is an object associated with the current file, its not global;
- `module` is another object associated with the current file, not global as well, `module.exports` is the wrapping function's return value;
- `__filename/__dirname` are the file's path and its directory path;

We can access all arguments like this as well:

```js
// main.js
console.log(arguments);
```

```sh
➜  learn-node node main.js
[Arguments] {
  '0': {},
  '1':
   { [Function: require]
     resolve: { [Function: resolve] paths: [Function: paths] },
     main:
      Module {
        id: '.',
        exports: {},
        parent: undefined,
        filename: '/home/gary/code/learn-node/main.js',
        loaded: false,
        children: [],
        paths: [Array] },
     extensions:
      { '.js': [Function],
        '.json': [Function],
        '.node': [Function],
        '.mjs': [Function] },
     cache: { '/home/gary/code/learn-node/main.js': [Module] } },
  '2':
   Module {
     id: '.',
     exports: {},
     parent: undefined,
     filename: '/home/gary/code/learn-node/main.js',
     loaded: false,
     children: [],
     paths:
      [ ... ] },
  '3': '/home/gary/code/learn-node/main.js',
  '4': '/home/gary/code/learn-node' }
```

### The `require` object

```js
// main.js
console.log(require);
```

```sh
➜  learn-node node main.js
{ [Function: require]
  resolve: { [Function: resolve] paths: [Function: paths] },
  main:
   Module {
     id: '.',
     exports: {},
     parent: undefined,
     filename: '/home/gary/code/learn-node/main.js',
     loaded: false,
     children: [],
     paths:
      [ ... ] },
  extensions:
   { '.js': [Function],
     '.json': [Function],
     '.node': [Function],
     '.mjs': [Function] },
  cache:
   { '/home/gary/code/learn-node/main.js':
      Module {
        id: '.',
        exports: {},
        parent: undefined,
        filename: '/home/gary/code/learn-node/main.js',
        loaded: false,
        children: [],
        paths: [Array] } } }
```

`require` is a function, and it has its properties as well:

- You can override it: `require = () => { mocked: true };`, this allows you to mock any module;
- `require.resolve` is a function that returns full path of a module;
- `require.extensions` contains loading functions for all supported file types;
- `require.main` is a reference to the entry module of current process, it can be used to check whether a module is being ran directly or being required;

  ```js
  // mod-a.js
  const print = name => {
    console.log(`Hello ${name}`);
  };

  if (require.main === module) {
    print(process.argv[2]); // print directly if this is the main file
  } else {
    module.exports = print;
  }
  ```

  ```sh
  ➜  learn-node node mod-a.js Gary
  Hello Gary
  ```

### Module Caching

```js
// mod-a.js
console.log('Running mod-a');
console.log(require.cache);
```

```sh
> require('./mod-a')  # first require, module gets loaded and cached

Running mod-a
{ '/home/gary/code/learn-node/mod-a.js':
   Module {
     id: '/home/gary/code/learn-node/mod-a.js',
     exports: {},
     parent:
      Module { ... },
     filename: '/home/gary/code/learn-node/mod-a.js',
     loaded: false,
     children: [],
     paths:
      [ ... ] } }

> require('./mod-a')  # doesn't load again
```

Node caches modules in `require.cache`, so if you `require` a module again, it just returns the cached exports, doesn't run the module code again.

### ECMAScript Modules in Node 11

Details are here https://nodejs.org/docs/latest-v11.x/api/esm.html

#### Enabling

If you want to use ES Module syntax with Node (not Babel transpiling)

- end your ES Module file with `.mjs`;
- use `--experimental-modules` flag in your command;

  ```node
  node --experimental-modules my-app.mjs
  ```

#### Features

- In a ESM module, `import.meta` metaproperty is an object containing the absolute `file:` URL of the module:

  ```js
  {
    url: 'file:///home/gary/code/nodejs/foo.mjs';
  }
  ```

- This syntax `require('./foo.mjs')` is not supported;

#### Differences between `import` and `require`

- `NODE_PATH` is not used by `import` (use symlinks if needed);
- `require.extensions` is not used by `import`;
- `require.cache` is not used by `import`;

### CommonJs vs. ES6 Modules

This blog post explains the implementation difference between the two module systems: [An Update on ES6 Modules in Node.js](https://medium.com/the-node-js-collection/an-update-on-es6-modules-in-node-js-42c958b890c)

- core difference: **ES Module loading is asynchronous, while CommonJS module loading is synchronous**;
- Babel/webpack load ES Modules _synchronously_, while the ECMAScript specs specify _asynchronous_ loading;

## Error Handling

[Error Handling | Joyent](https://www.joyent.com/node-js/production/design/errors)

1. An _error_ is any instance of the `Error` class, it becomes an _exception_ when you `throw` it;

1. Main ways of delivering an error:

   1. `throw` it;
   1. pass it to a _callback_ function, which handles both errors and results of a async operation;
   1. pass it a a _reject_ promise function;
   1. emit an `"error"` event on an EventEmitter;

1. In Node, because most errors are async, it's more common to use a callback function to handle errors, instead of `try...catch`, unlike Java or C++;

### Operational errors vs. programmer errors

- **Operational errors** are not bugs, they are external problems faced by correct programs at runtime, they can't be avoided by changing the program, such as:

  - invalid user input
  - failed to connect to server / resolve a hostname
  - server returned a 500 response
  - system out of memory

- **Programmer errors** are bugs in the program, can be avoided by changing the code, they can't be handled properly:
  - read 'undefined' property
  - pass a 'string' where an object is expected

An programmer error in a server program usually means an operational error for a client program; and another way around, if you don't handle an operational error(i.e. network failure) properly, then the whole program crashes, this becomes a programmer error.

### Handling operational errors

- Any code that does anything which may fail(opening a file, connecting to a server, etc) _has_ to consider how to deal with a failed operation;
- You may need to deal with the same error at several levels of the stack, sometimes only the top-level caller knows how to deal with an error;

For any given error, you might:

- **Deal with it directly**, when it's clear what you have to do:

  - creating a log file first when it is not found;
  - try to reconnect a failed persistent connection to a db server;

- **Propagate the failure to your client**, you don't know how to deal with the error, then you should abort the operation, clean up whatever you've started and deliver an error back, this is often appropriate when you expect the cause of the error is not changing soon:

  - failed to parse invalid JSON input;

- **Retry**, sometimes useful for network and remote service errors

  - You should document clearly how many times you may retry and how long you'll wait between retries;
  - And don't retry at every level of the stack;

- **Crash**, when something representing programmer errors happened, or there's nothing you can do.

- **Log the error and do nothing**, when something happend, you can do nothing and there's no need to crash the program, you should just log a message and proceed.

### Programmer errors

- The best way to recover from programmer errors is to **crash immediately**;
- You should run your program using a restarter to automatically restart the program in the event of a crash;

## Debugging

start a program with the `--inspect` flag

```bash
node --inspect demo.js

# break at the first line
node --inspect-brk demo.js
```

by default the Node process listens via WebSocket on `127.0.0.1:9229` for debugging messages, a debugger programe then connect to this url (e.g. `ws://127.0.0.1:9229/0f2c936f-b1cd-4ac9-aab3-f63b0f33d55e`). You can also get metadata about the program via a HTTP endpoint (`http://[host:port]/json/list`).

### Command line debugging

```sh
node inspect demo.js
```

This spawns a child process to run the script under `--inspect` flag; and use main process to run CLI debugger

### Remote debugging

don't bind the node inspector to a public IP address, instead connect to it through SSH

on remote machine, start the Node process:

```bash
node --inspect server.js
```

on local, start port forwarding

```bash
ssh -L 9221:localhost:9229 user@remote.example.com
```

then connect to `9221` on local using any debugging client.

## Barebone HTTP server

```js
var http = require('http');

var server = http.createServer(function(req, resp) {
  resp.writeHead(200, { 'Content-Type': 'text/plain' });
  resp.end('Hello World');
});

server.listen(8000);

console.log('Server running at http://localhost:8000');
```


## CLI

### Limit memory usage

https://nodejs.org/dist/latest-v10.x/docs/api/cli.html

Use V8 option `--max-old-space-size` to limit Node's memory usage (the number is in MB):

```sh
# set it in NODE_OPTIONS environment variable
NODE_OPTIONS='--max-old-space-size=100' node script.js

# or set it directly in the command line
node --max-old-space-size=100 script.js
```

## Tools

### `nvm` - manage multiple versions of Node

You can use [nvm](https://github.com/creationix/nvm) to manage multiple versions of Node

```shell
# list installed versions
nvm ls

# list all available versions
nvm ls-remote
```

### NPM

npm's config file is at `~/.npmrc`, can be updated with `npm config set`

```shell
# save dependencies to `package.json` file when installing
npm config set save=true

# save the exact version
npm config set save-exact=true
```

#### `package.json`

- it's a JSON file, comments are **NOT** allowed;
- you can use `//` key for comments, since duplicate keys are removed after you run any `npm` command, so make sure only use `//` once per block, or append something after `//` for each comment key to be unique:

```json
{
  "scripts": {
    "// --- comment ---": "echo this is a comment",
    "build": "echo building"
  },
  "//": ["first line", "second line"]
}
```


#### Avoid installing packages globally

_Since npm 5.2, there is a tool `npx` bundled with npm_, you can use it to run some scripts without installing a global package, such as

    npx create-react-app my-app

[The Issue With Global Node Packages](https://www.smashingmagazine.com/2016/01/issue-with-global-node-npm-packages/)

Notes:

- Install all dependencies of a project locally (with `--save`, `--save-dev`);
- All the binary tools should be available in `node_modules/.bin/`, you can add `./node_modules/.bin/` to your `$PATH`, but then you can only run these tools in the root directory of the project;
- A good practice is adding these tools as alias in `package.json`

  ```json
  {
      …
      "scripts": {
          "build": "browserify main.js > bundle.js"
      }
      …
  }
  ```

  then you just need to run `npm run build`, you can add options to the original tool by adding them following `--`: `npm run build -- --debug`

#### Publish package to NPM

(https://docs.npmjs.com/getting-started/publishing-npm-packages)

- Create an account on NPM;
- Review the package directory:
  - everything in the directory will be included unless ignored by `.gitignore` or `.npmignore`;
  - review `package.json`;
  - choose a name;
  - include a `readme.md` file;
- `npm publish`;

update a package:

- `npm version (patch|minor|major)`
  it will change the version number in `package.json`, (will also add a tag to the linked git repo)
- `npm publish`

#### Symlink a package folder

make one local package available to another project, quite useful for developing and testing a library package

two steps process:

```bash
cd ~/code/myLibrary
npm link                # symlinks this to a global folder

cd ~/code/myApp
npm link my-library     # link to this package, use the 'name' in package.json, not the directory name
```

or a shortcut:

```bash
cd ~/code/myApp
npm link ../myLibrary   # use 'my-library' in code of myApp
```

### Yarn

```bash
# save to devDependencies
yarn add -D [packages ...]

# make sure the installed files are matching the specified version
yarn add --check-files [packages ...]

# upgrade packages to their latest versions, package.json is updated as well
yarn upgrade pkg1 pkg2 --latest
yarn upgrade --scope @pkg-namespace --latest

# the above is not working somehow, used the following line
yarn upgrade pkg1@latest pkg2@latest
```

[daniel-khan]: (https://youtu.be/gl9qHml-mKc)
[bert-belder]: (https://youtu.be/PNa9OMajw9w)
[erin-zimmer]: (https://youtu.be/u1kqx6AenYw)
[deepal-jayasekara]: (https://blog.insiderattack.net/event-loop-and-the-big-picture-nodejs-event-loop-part-1-1cb67a182810)