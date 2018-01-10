Redux
===========

Redux is an implementation of the Flux pattern intended to manage an app's state.


## testing

    npm install --save-dev jest babel-jest

config `.babelrc`

    {
      "presets": ["es2015"]
    }

config `package.json`

    {
      ...
      "scripts": {
        ...
        "test": "jest",
        "test:watch": "npm test -- --watch"
      },
      ...
    }
