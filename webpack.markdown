Webpack
=================

## install

	npm init
	npm install webpack --save-dev


### loaders

* Babel

		npm install babel-loader babel-core --save-dev

		// need this to determine what need transpiling: es2015 and JSX
		npm install babel-preset-es2015 babel-preset-react --save-dev

* CSS

		// to include css files
		npm install style-loader css-loader --save-dev

		// to compile sass files
		npm install sass-loader node-sass --save-dev

* Images

		npm install url-loader file-loader --save-dev

### frameworks

	// to use React and ReactDOM
	npm install react react-dom --save

### other

	// live reloading
	npm install webpack-dev-server --save-dev


## webpack 1 vs. webpack 3

### webpack 1

`webpack.config.js`

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


### webpack 3

with webpack 3, you should use `babel-preset-env` instead of `babel-preset-latest` and `babel-preset-stage0`
and you should use a `.babelrc` file

`webpack.config.js`

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


`.babelrc`

    {
        presets: ["env", "react"]
    }
