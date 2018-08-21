Babel
============


## install

* Node

```bash
sudo npm install babel babel-cli
```

* working with webpack

```bash
npm init

sudo npm install webpack
sudo npm install --save-dev babel-loader
```

**NOTE** it's not a good idea to install Babel globally, that would make your project dependent on a specific system env;


## Babel configs:

put the following in `.babelrc` to use the latest Babel features:

```json
{
	"presets": ["env"],
}
```


## Compile

* compile for browser

```bash
babel script.js --watch --out-file script-compiled.js
```

* run node js script

```bash
babel-node node-script.js
```

* or use webpack

```bash
webpack --watch
```

## Debugging

in VSCode `launch.json`

```json

...

// babel-node debugging demo
{
	"type": "node",
	"request": "launch",
	"name": "Babel Node",
	"program": "${file}",
	"runtimeExecutable": "${workspaceRoot}/node_modules/.bin/babel-node",
	"args": []
},

// babel-node attaching demo
{
	"type": "node",
	"request": "attach",
	"name": "Babel Node Attaching",
	"port": 9229,
	"timeout": 120000,
	"localRoot": "${workspaceFolder}/",
},

...

```

for attaching mode, launch the script like this:

```bash
babel-node --inspect=9229 app.js
```


## include babeljs in browser

**make sure the `charset="utf-8"` attribute is included**

```html
<script src="https://unpkg.com/babel-core@5.8.38/browser.min.js" charset="utf-8"></script>
```
