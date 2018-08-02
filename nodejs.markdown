NodeJS notes
============

- [NodeJS notes](#nodejs-notes)
    - [Multiple versions of Node.js](#multiple-versions-of-nodejs)
    - [Blocking vs non-blocking](#blocking-vs-non-blocking)
    - [NPM](#npm)
        - [Avoid installing packages globally](#avoid-installing-packages-globally)
        - [Publish package to NPM](#publish-package-to-npm)
    - [Module System - CommonJs vs. ES6 Modules](#module-system---commonjs-vs-es6-modules)
        - [Current status in Node 9/10](#current-status-in-node-910)
    - [Debugging](#debugging)
        - [Remote debugging](#remote-debugging)
    - [Streams and pipes](#streams-and-pipes)
        - [read](#read)
        - [write](#write)
        - [pipe](#pipe)
        - [events](#events)

## Multiple versions of Node.js 

use [nvm](https://github.com/creationix/nvm) to manage multiple versions of Node

```shell
# list installed versions
nvm ls

# list all available versions
nvm ls-remote
```

## Blocking vs non-blocking

* All of the I/O methods in the Node.js standard library provide asynchronous versions, which are **non-blocking**, and accept callback functions. Some methods also have **blocking** counter parts, which have names that end with `Sync`.

* JavaScript execution in Node.js is single threaded, so concurrency refers to the event loop's capacity to execute JavaScript call back functions after completing other work.


## NPM 

npm's config file is at `~/.npmrc`, can be updated with `npm config set`

```shell
# save dependencies to `package.json` file when installing
npm config set save=true

# save the exact version
npm config set save-exact=true
```

### Avoid installing packages globally

*Since npm 5.2, there is a tool `npx` bundled with npm*, you can use it to run some scripts without installing a global package, such as 

    npx create-react-app my-app


[The Issue With Global Node Packages](https://www.smashingmagazine.com/2016/01/issue-with-global-node-npm-packages/)

some notes:

* installing all dependencies of a project locally (with `--save`, `--save-dev`);
* all the binary tools should be available in `node_modules/.bin/`, you can add `./node_modules/.bin/` to your `$PATH`, but then you can only run these tools in the root directory of the project;
* a good practice is adding these tools as alias in `package.json`
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

### Publish package to NPM

(https://docs.npmjs.com/getting-started/publishing-npm-packages)

* Create an account on NPM;
* Review the package directory:
    * everything in the directory will be included unless ignored by `.gitignore` or `.npmignore`;
    * review `package.json`;
    * choose a name;
    * include a `readme.md` file;
* `npm publish`;

update a package:

* `npm version (patch|minor|major)`
    it will change the version number in `package.json`, (will also add a tag to the linked git repo)
* `npm publish`


## Module System - CommonJs vs. ES6 Modules

this blog post explains the implementation difference between the two module systems: [An Update on ES6 Modules in Node.js](https://medium.com/the-node-js-collection/an-update-on-es6-modules-in-node-js-42c958b890c)

* core difference: **ES Module loading is asynchronous, while CommonJS module loading is synchronous**;
* Babel/webpack load ES Modules *synchronously*, while the ECMAScript specs specify *asynchronous* loading;

### Current status in Node 9/10
details are here https://nodejs.org/docs/latest-v9.x/api/esm.html

more info: https://medium.com/@giltayar/native-es-modules-in-nodejs-status-and-future-directions-part-i-ee5ea3001f71

if you want to use ES Module syntax with Node (not Babel transpiling)

* end your ES Module file with `.mjs`;
* use `--experimental-modules` flag in your command;

    ```node
    node --experimental-modules test.mjs
    ```


## Debugging

start a program with the `--inspect` flag

```bash
node --inspect demo.js

# break at the first line
node --inspect-brk demo.js
```

by default the Node.js process listens via WebSocket on `127.0.0.1:9229` for debugging messages, a debugger programe then connect to this url (e.g. `ws://127.0.0.1:9229/0f2c936f-b1cd-4ac9-aab3-f63b0f33d55e`). You can also get metadata metadata about the program via a HTTP endpoint (`http://[host:port]/json/list`).



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


## Streams and pipes

Node makes extensive use of streams, there are fundamental stream types in Node.js:
* **Readable**: such as `fs.createReadStream`;
* **Writable**: such as `fs.createWriteStream`;
* **Duplex**: both readable and writable, such as a TCP socket;
* **Transform**: a duplex stream that can be used to modify or transfer the data, such as `zlib.createGzip`;

all streams are instances of `EventEmitter`, they emit events that can be used to read and write data, however, we can consume streams data in a simpler way using the `pipe` method

```node
readableSrc.pipe(writableDest)
```

or

```node
readableSrc
  .pipe(transformStream1)
  .pipe(transformStream2)
  .pipe(finalWrtitableDest)
```

it's recommended to use either the `pipe` method or consume streams with events, but don't mix them

### read

```node
var fs = require("fs");
var stream;
stream = fs.createReadStream("/data/test.txt");

stream.on("data", function(data) {
    var chunk = data.toString();
    console.log(chunk);
}); 
```

### write

```node
var fs = require("fs");
var stream;
stream = fs.createWriteStream("/data/test.txt");

stream.write("Node.js")
stream.write("Hello World") 
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
