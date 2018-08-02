Webpack
=================

Most content based on Webpack 4, if not specified specifically.

[A tale of Webpack 4 and how to finally configure it in the right way]( https://hackernoon.com/a-tale-of-webpack-4-and-how-to-finally-configure-it-in-the-right-way-4e94c8e7e5c1)


## Install

```bash
yarn init
yarn add -D webpack webpack-cli
```

## Default Behaviour

Webpack 4 requires zero configuration, it would try to use `src/index.js` as entry and `dist/main.js` as output.


## Add building commands to `package.json`

add the following to `scripts` field in `package.json`:

```json
"scripts": {
    "dev": "webpack --mode development",
    "build": "webpack --mode production"
}
```

`development` mode supports hot module replacement, dev server and other things assisting dev work 

then you can just use

```shell
yarn dev
```
or
```shell
yarn build
```

## Configs

* `externals`

    excluding dependencies from the output bundles, the created bundle relies on the dependency to be present in the consumers' environment, you can also specify how it will be available in run time with different module context (commonjs, amd, ES2015)

    ```js
    module.exports = {
        //...
        externals : {
            react: 'react'                  // react will be available as 'react' in global env
        },

        // or

        externals : {
            lodash : {
                commonjs: 'lodash',         // in commonjs context, it will be available as 'lodash'
                amd: 'lodash',              // same as above
                root: '_'                   // available as '_' global variable
            }
        },

        // or

        externals : {
            subtract : {
                root: ['math', 'subtract']  // will be available as window['math']['subtract']
            }
        }
    };
    ```

* `entry` -> `vendor`

    make your app and the vendor code separate from each other, this setup allows you to leverage `CommonsChunkPlugin` and extract any vendor references from your app bundle into your vendor bundle;

* `resolve` 

    controls how webpack finds modules included by `require / import` statements, some of the common fields:

    ```json
    resolve: {
        // whether resolve symlinks
        symlinks: false,

        // file extensions to try
        extensions: [".js", ".jsx", ".json"],

        // modules in your own 'src' folder take precedence over 'node_modules'
        // if your import 
        modules: [path.resolve(__dirname, "src"), "node_modules"]
    }
    ```

    resolving steps:



* `targets`

    set the environment you are targeting, usually:

    * `web`: default value;
    * `node`: compile for usage in Node environment (using Node.js `require` to load chunks, and not touch any built in modules like `fs` or `path`, as they are always available in the target Node environment);
    * `async-node`: uses `fs` and `vm` to load chunks asynchronously (`require` loads chunks synchronously)

    you can create an isomophic library by bundling two separate configurations:

    ```node
    const path = require('path');
    const serverConfig = {
        target: 'node',
        output: {
            path: path.resolve(__dirname, 'dist'),
            filename: 'lib.node.js'
        }
        //…
    };

    const clientConfig = {
        target: 'web', // <=== can be omitted as default is 'web'
        output: {
            path: path.resolve(__dirname, 'dist'),
            filename: 'lib.js'
        }
        //…
    };

    module.exports = [ serverConfig, clientConfig ];
    ```

    exporting a config array, not a single config, it will create both `lib.node.js` and `lib.js` in `dist` folder

* `devtool`

    defines how source maps are generated, suggested settings:

    * in dev: `devtool: 'cheap-module-eval-source-map',`,
    * in production: `devtool: 'cheap-module-source-map',`,

    see details here [webpack - Devtool](https://webpack.js.org/configuration/devtool/)

    `output.devtoolModuleFilenameTemplate` is used to customize the names used in each source map's `sources` array

    ```js
    module.exports = {
        //...
        output: {
            devtoolModuleFilenameTemplate: 'webpack://[namespace]/[resource-path]?[loaders]'
        }
    };
    ```

    `output.devtoolNamespace` can be used to customize the `[namespace]` part above, used to prevent source file path collisions in source maps when loading multiple libraries built with webpack;

    This affects your debug launching config in VS Code, see here (https://github.com/Microsoft/vscode-chrome-debug) for details, you may need to change the `sourceMapPathOverrides` part

    ```json
    {
        "type": "chrome",
        "request": "attach",
        "skipFiles": [
            "${workspaceFolder}/node_modules/**/*.js",
            "<node_internals>/**/*.js"
        ],
        "name": "Launch Chrome against localhost",
        "url": "http://localhost:8080/*",
        "port": 9222,
        "sourceMapPathOverrides": {
            "webpack:///./*"    : "${webRoot}/*",                
            "webpack:///*"      : "${webRoot}/*",                
        },
        "webRoot": "${workspaceFolder}"
    }
    ```

## Build a library 

`webpack.config.js`

```js
var path = require('path');

module.exports = {
    entry: './src/index.js',

    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'webpack-numbers.js',
        library: 'webpackNumbers',  // name of the global variable when imported
        libraryTarget: 'umd'        // consumer can include in CommonJS, ES2015, and as a global variable
    },

    // exclude lodash from the final library file, it should be a dependency 
    externals: {
        lodash: {
            commonjs: 'lodash',
            commonjs2: 'lodash',
            amd: 'lodash',
            root: '_'
        }
    }
};
```

in `package.json`

```js
{
  "name": "my-library",
  "version": "1.0.0",
  "description": "My Library",
  "main": "dist/index.js",          // the entry file for consumers
  "files": [                        // files need to be uploaded to npm
    "dist"
  ],

  ...
}
```


## Plugins

* `Jarvis`

    shows info about your webpack build, the count of ES Harmony module imports which can be treeshakable and the CJSs ones which are not;


## Loaders

* Babel

    ```shell
    yarn add -D babel-core babel-loader babel-preset-env
    ```

    add a `.babelrc` file


    ```json
    {
        "presets": [
            "env"
        ]
    }
    ```

* CSS

    ```bash
    # to include css files
    yarn add -D style-loader css-loader

    # to compile sass files
    yarn add -D sass-loader node-sass
    ```

* Images

    ```bash
    yarn add -D url-loader file-loader
    ```


## A simple config file

```js
// webpack v4
const path = require('path');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
module.exports = {
  entry: { main: './src/index.js' },
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'main.js'
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      },
      {
        test: /\.scss$/,
        use: ExtractTextPlugin.extract(
          {
            fallback: 'style-loader',
            use: ['css-loader', 'sass-loader']
          })
      }
    ]
  },
  plugins: [ 
    new ExtractTextPlugin(
      {filename: 'style.css'}
    ),
    new HtmlWebpackPlugin({
      inject: false,
      hash: true,
      template: './src/index.html',
      filename: 'index.html'
    })
  ]
};
```


## Webpack 1 vs. Webpack 3

### Webpack 1

`webpack.config.js`

```js
var webpack = require("webpack");

module.exports = {
    entry: './src/index.js',

    output: {
        path: './dist/assets/',
        filename: 'bundle.js',
        publicPath: 'assets',
    },

    devServer: {
        inline: true,
        contentBase: './dist',
        port: 3000
    },

    module: {
        loaders: [
            {
                test: /\.js$/,
                exclude: /(node_modules)/,
                loader: ['babel-loader'],
                query: {    // query for a loader
                    presets: ["latest", "stage-0", "react"]
                }
            },
            {
                test: /\.json$/,
                exclude: /(node_modules)/,
                loader: 'json-loader',  // NOTE: loader can be an array or a string
            },
            {
                test: /\.css$/,
                exclude: /(node_modules)/,
                loader: 'style-loader!css-loader!autoprefixer-loader',
            },
            {
                test: /\.scss$/,
                exclude: /(node_modules)/,
                loader: 'style-loader!css-loader!autoprefixer-loader!sass-loader',
            },

        ],
    }
}
```

### Webpack 3

with webpack 3, you should use `babel-preset-env` instead of `babel-preset-latest` and `babel-preset-stage0`
and you should use a `.babelrc` file

`webpack.config.js`

```js
var webpack = require("webpack");

module.exports = {
    entry: './src/index.js',

    output: {
        filename: 'bundle.js',
    },

    devServer: {
        inline: true,
        contentBase: './dist',
        port: 3000
    },

    module: {
        rules: [        // 'loaders' changed to 'rules'
            {
                test: /\.js$/,
                exclude: /(node_modules)/,
                loader: 'babel-loader',
                query: {
                    presets: ["env", "react"]   // use 'env' here
                }
            },
            {
                test: /\.json$/,
                exclude: /(node_modules)/,
                loader: 'json-loader',
            },
            {
                test: /\.css$/,
                exclude: /(node_modules)/,
                loader: 'style-loader!css-loader!autoprefixer-loader',
            },
            {
                test: /\.scss$/,
                exclude: /(node_modules)/,
                loader: 'style-loader!css-loader!autoprefixer-loader!sass-loader', // <- loaders are applied from right to left
            },

        ],
    }
}
```

`.babelrc`

```json
{
    presets: ["env", "react"]
}
```
