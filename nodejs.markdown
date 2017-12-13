NodeJS notes
============

## update nodejs

[How to update node.js](http://stackoverflow.com/questions/8191459/how-to-update-node-js)

    sudo npm cache clean -f
    sudo npm install -g n
    sudo n stable
    
    // sudo n 0.8.20  // install a specific version


## blocking vs non-blocking

* All of the I/O methods in the Node.js standard library provide asynchronous versions, which are **non-blocking**, and accept callback functions. Some methods also have **blocking** counter parts, which have names that end with `Sync`.

* JavaScript execution in Node.js is single threaded, so concurrency refers to the event loop's capacity to execute JavaScript call back functions after completing other work.


## npm 

npm's config file is at `~/.npmrc`, can be updated with `npm config set`

	npm config set save=true		// save dependencies to `package.json` file when installing
	npm config set save-exact=true	// save the exact version

### avoid installing packages globally

[The Issue With Global Node Packages](https://www.smashingmagazine.com/2016/01/issue-with-global-node-npm-packages/)

some notes:

* installing all dependencies of a project locally (with `--save`, `--save-dev`);
* all the binary tools should be available in `node_modules/.bin/`, you can add `./node_modules/.bin/` to your `$PATH`, but then you can only run these tools in the root directory of the project;
* a good practice is adding these tools as alias in `package.json`

        {
            …
            "scripts": {
                "build": "browserify main.js > bundle.js"
            }
            …
        }

    then you just need to run `npm run build`, you can add options to the original tool by adding them following `--`: `npm run build -- --debug` 
