# Jest

- [Setup](#setup)
  - [Using Babel](#using-babel)
- [Configs](#configs)
  - [Options](#options)

## Setup

```bash
yarn add -D jest babel-jest
```

`package.json`

```json
{
    ...
    "scripts": {
    ...
    "test": "jest",
    "test:watch": "npm test -- --watch"
    },
    ...
}
```

### Using Babel

```js
// babel.config.js
module.exports = api => {
  const isTest = api.env("test");

  // You can use isTest to determine what presets and plugins to use.

  return {
    // ...
  };
};
```

- **`babel-jest` will be installed automatically when installing Jest and will automatically transform files if a babel config exists in your project**;
- Jest will set `process.env.NODE_ENV` to `test` if it's not already set, you can use that in your babel configuration;

## Configs

Config can be defined

- In `package.json`

  ```json
  {
      ...
      "jest": {
          "verbose": true,
          ...
      }
      ...
  }
  ```

- In `jest.config.js`

  use `jest --init` to generate this file

  ```js
  module.exports = {
    verbose: true
  };
  ```

- Using the `--config` option;

### Options

- `roots`

  Where to find test files and source files, default to `["<rootDir>"]`

  ```json
  {
    "roots": ["<rootDir>/src/", "<rootDir>/tests/"]
  }
  ```

- `testMatch`

  The glob patterns for locating test files, by default it looks for:
  _ Files in `__tests__` folders;
  _ Files with a suffix of `.test` or `.spec`;

  Default:

  ```json
  {
    "testMatch": [
      "**/__tests__/**/*.[jt]s?(x)",
      "**/?(*.)+(spec|test).[tj]s?(x)"
    ]
  }
  ```

- `testRegex`

  The pattern for locating test files. Use this or `testMatch`, not both;

- `globals`

  Can be used in accordance with `webpack.DefinePlugin`

  ```json
  {
    "globals": {
      "__DEV__": true
    }
  }
  ```

- `moduleDirectories`

  Use this in accordance with webpack's `resolve.modules` option

  ```json
  {
    "moduleDirectories": ["src/components", "node_modules"]
  }
  ```
