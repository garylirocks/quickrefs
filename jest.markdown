Jest
===========

## Setup

```bash
yarn add -D jest babel-jest
```

config `.babelrc`

```json
{
    "presets": ["env"]
}
```

config `package.json`

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
