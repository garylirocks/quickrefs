# VS Code

- [Shortcuts](#shortcuts)
- [VSCodeVim plugin](#vscodevim-plugin)
  - [Visual block mode](#visual-block-mode)
  - [Column selection mode](#column-selection-mode)
  - [Selection](#selection)
  - [Navigation/Action](#navigationaction)
  - [Editing](#editing)
  - [With NeoVim Enabled](#with-neovim-enabled)
- [Formatting / Linting](#formatting--linting)
  - [ESLint](#eslint)
    - [`extends` vs `plugins`](#extends-vs-plugins)
  - [Run Prettier and ESLint together](#run-prettier-and-eslint-together)
- [Debugging](#debugging)
  - [Trouble shooting](#trouble-shooting)
  - [Sample debugging settings for React / Mocha](#sample-debugging-settings-for-react--mocha)
- [Mac trivias](#mac-trivias)

## Shortcuts

- `Ctrl + Shift + L`: multi word cursors/selections, allows you to change multi occurrences of a word simultaneously

## VSCodeVim plugin

### Visual block mode

Usually only useful when you have fixed width fields, see note in [vim.markdown](./vim.markdown)

### Column selection mode

1. In visual mode, select all the lines you want to edit;
1. Toggle Column Selection Mode, by Command Palette, or a shortcut;
1. Escape, now you have a cursor on each line, do whatever you want;

### Selection

- `af`: in visual mode, select a larger block increasingly

### Navigation/Action

- `gd`: go to definition;
- `gh`: show hover message (types or error messages);
- `Shift + <Esc>`: close popup boxes;

### Editing

- `gb`: toggle multi-cursor mode, add cursor to the next word which is the same as current one under cursor, similar to `Ctrl + Shift + L`, but add cursor one by one
- `gc`: toggle line comment, `gcc` for current line, `gc2j` for current and next 2 lines;
- `gC`: toggle block comment;
- `gq`: reflow and wordwrap long comment lines

### With NeoVim Enabled

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

- (Recommended) Turn off ESLint's formatting rules that might conflict with Prettier

  ```sh
  # eslint-config-prettier turns off all ESLint rules that might interfere with Prettier rules
  yarn add --dev eslint-config-prettier
  ```

  `.eslintrc.json`:

  ```json
  {
    "extends": ["prettier"] // configs(a set of rules) from eslint-config-prettier
  }
  ```

- Use ESLint to run Prettier

  ```sh
  # eslint-plugin-prettier turns Prettier rules into ESLint rules
  yarn add --dev prettier eslint-plugin-prettier
  ```

  `.eslintrc`

  ```json
  {
    "plugins": ["prettier"],
    "rules": {
      // rules from eslint-plugin-prettier
      "prettier/prettier": "error"
    }
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
      "name": "Node debug: Attach to Process",
      "port": 9229,
      "timeout": 120000,
      "localRoot": "${workspaceFolder}",
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
