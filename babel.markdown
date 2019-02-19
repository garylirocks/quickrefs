# Babel

- [Install](#install)
  - [Include babel in browser](#include-babel-in-browser)
- [Babel Configs](#babel-configs)
  - [`babel.config.js`](#babelconfigjs)
  - [`.babelrc`](#babelrc)
- [Compile](#compile)
- [Debugging](#debugging)

## Install

- Node

  ```bash
  sudo npm install babel babel-cli

  # after v7
  sudo npm install @babel/core @babel/cli @babel/preset-env
  ```

- Working with webpack

  ```bash
  npm init

  sudo npm install webpack
  sudo npm install --save-dev babel-loader
  ```

**NOTE**: it's not a good idea to install Babel globally, that would make your project dependent on a specific system env;

### Include babel in browser

**Make sure the `charset="utf-8"` attribute is included**

```html
<script
  src="https://unpkg.com/babel-core@5.8.38/browser.min.js"
  charset="utf-8"
></script>
```

## Babel Configs

See [Config Files - Babel](https://babeljs.io/docs/en/config-files) for details.

### `babel.config.js`

The recommended way for configs, should be in the root of a project.

```js
module.exports = function (api) {
  api.cache(true);

  const presets = [ ... ];
  const plugins = [ ... ];

  return {
    presets,
    plugins
  };
}
```

### `.babelrc`

The old method for configs, put the following in `.babelrc` to use the latest Babel features.

```json
{
  "presets": ["env"]
}
```

## Compile

- compile for browser

  ```bash
  babel script.js --watch --out-file script-compiled.js
  ```

- run node js script

  ```bash
  babel-node node-script.js
  ```

- or use webpack

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
