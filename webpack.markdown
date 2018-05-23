Webpack
=================

Most content based on Webpack 4, if not specified specifically.

[A tale of Webpack 4 and how to finally configure it in the right way]( https://hackernoon.com/a-tale-of-webpack-4-and-how-to-finally-configure-it-in-the-right-way-4e94c8e7e5c1)


## Install

	yarn init
	yarn add -D webpack webpack-cli


## Default Behaviour

Webpack 4 requires zero configuration, it would try to use `src/index.js` as entry and `dist/main.js` as output.


## Add NPM scripts

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
                loader: 'style-loader!css-loader!autoprefixer-loader!sass-loader',
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
