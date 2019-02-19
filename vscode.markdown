# VS Code

- [Shortcuts](#shortcuts)
  - [with Vim plugin](#with-vim-plugin)
- [Formatting / Linting](#formatting--linting)
  - [ESLint](#eslint)
    - [`extends` vs `plugins`](#extends-vs-plugins)
  - [Run Prettier and ESLint together](#run-prettier-and-eslint-together)
- [Debugging](#debugging)
  - [Trouble shooting](#trouble-shooting)
  - [Sample debugging settings for React / Mocha](#sample-debugging-settings-for-react--mocha)
- [Mac trivias](#mac-trivias)

## Shortcuts

- multi word cursors/selections, allows you to change multi occurence of a word simutaneously: `Ctrl + Shift + L`
- `Command + Alt + C`: copy absolute path of current file

### with Vim plugin

- `gd`: go to definition;
- `gh`: show hover message (types or error messages);
- `af`: in visual mode, select a larger block increasingly;
- `Shift + <Esc>`: close popup boxes;
- `gc`: toggle line comment, `gcc` for current line, `gc2j` for current and next 2 lines;
- `gC`: toggle block comment;

- when neovim is installed:
  - `:g/foo/co$` copy all lines with `foo` to the end of file;

## Formatting / Linting

- Editorconfig

  - Config editors to follow some style rules;
  - Happens when you type;

* Prettier

  - Format a file according to specified rules;
  - Can happen when you save a file or configed in a pre-commit hook;
  - Prettier respects `.editorconfig`, but its own config `prettier.config.js` takes precedence;

* Linting
  - Linters have two categories of rules:
    - Formatting rules, `max-len`, `no-mixed-spaces-and-tabs`, ..., Prettier can do all this;
    - Code-quality rules, `no-unused-vars`, `no-implicit-globals`, ..., which can catch bugs in your code, Prettier can't do this;

### ESLint

#### `extends` vs `plugins`

[What's the difference between plugins and extends in eslint?](https://stackoverflow.com/questions/53189200/whats-the-difference-between-plugins-and-extends-in-eslint)

- `extends` an easy way to apply a set of rules (using a config file), of which you can override individually;

* A plugin provides you with a set of rules, adding a plugin to `plugins` option doesn't enforce any rules by default, you need to apply them individually. It may also provide config files, it that case you can add them to `extends`;

### Run Prettier and ESLint together

ESLint's rules regarding code style may conflict with Prettier, to make them work together, either:

- Use ESLint to run Prettier

  ```sh
  yarn add --dev prettier eslint-plugin-prettier
  ```

  `.eslintrc`

  ```
  {
    "plugins": ["prettier"],
    "rules": {
      "prettier/prettier": "error"
    }
  }
  ```

- Turn off ESLint's formatting rules

  ```sh
  yarn add --dev eslint-config-prettier
  ```

  `.eslintrc.json`:

  ```json
  {
    "extends": ["prettier"]
  }
  ```

## Debugging

see [vscode-chrome-debug](https://github.com/Microsoft/vscode-chrome-debug) for some settings for the Chrome Debugger

### Trouble shooting

- in Debug Console, you can use `.scripts` command to see a list of all scripts loaded in the runtime, sourcemap infomation, and how they are mapped to files on disk.

  The output is like this:

  ```
  › <The exact URL for a script, reported by Chrome> (<The local path that has been inferred for this script, using webRoot, if applicable>)
      - <The exact source path from the sourcemap> (<The local path inferred for the source, using sourceMapPathOverrides, or webRoot, etc, if applicable>)
  ```

  ```
  › /app/index.js (/Users/gary/code/MyApp/index.js)
      - /app/index.js (/Users/gary/code/MyApp/index.js)
  ```

  use `sourceMapPathOverrides` or `webRoot` to make sure file paths are mapped correctly

### Sample debugging settings for React / Mocha

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Mocha Tests - in docker",
      "port": 9229,
      "timeout": 120000,
      "protocol": "inspector",
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/app",
      "restart": true,
      "sourceMaps": false,
      "internalConsoleOptions": "neverOpen"
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Mocha Tests - current file in local",
      "runtimeExecutable": "yarn",
      "runtimeArgs": ["debug-test", "${file}"],
      "sourceMaps": false,
      "internalConsoleOptions": "openOnSessionStart"
    },
    {
      "type": "chrome",
      "request": "attach",
      "skipFiles": [
        "${workspaceFolder}/node_modules/**/*.js",
        "<node_internals>/**/*.js"
      ],
      "name": "Debug in Chrome",
      "url": "http://localhost:8080/*",
      "port": 9222,
      "sourceMapPathOverrides": {
        "webpack://my-library/src/*": "${workspaceFolder:my-library}/src/*", // for my library
        "webpack:///./*": "${webRoot}/*", // Example: "webpack:///./node-modules/*"    -> "/Users/me/project/node-modules/*"
        "webpack:///*": "${webRoot}/*" // Example: "webpack:///src/app.js"          -> "/Users/me/project/src/app.js"
      },
      "webRoot": "${workspaceFolder:project1}"
    }
  ]
}
```

## Mac trivias

Mac does not repeat the holded down key, fix it (https://stackoverflow.com/questions/39972335/how-do-i-press-and-hold-a-key-and-have-it-repeat-in-vscode/44010683#44010683)

```bash
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
```
