VS Code
=============

- [VS Code](#vs-code)
    - [Shortcuts](#shortcuts)
    - [Debugging](#debugging)
        - [Trouble shooting](#trouble-shooting)
        - [Sample debugging settings for React / Mocha](#sample-debugging-settings-for-react--mocha)
    - [Mac trivias](#mac-trivias)


## Shortcuts

* multi word cursors/selections, allows you to change multi occurence of a word simutaneously: `Ctrl + Shift + L`


## Debugging

see [vscode-chrome-debug](https://github.com/Microsoft/vscode-chrome-debug) for some settings for the Chrome Debugger

### Trouble shooting

* in Debug Console, you can use `.scripts` command to see a list of all scripts loaded in the runtime, sourcemap infomation, and how they are mapped to files on disk.

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
            "runtimeArgs": [
                "debug-test",
                "${file}"
            ],
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
                "webpack://my-library/src/*": "${workspaceFolder:my-library}/src/*",  // for my library
                "webpack:///./*"    : "${webRoot}/*",                // Example: "webpack:///./node-modules/*"    -> "/Users/me/project/node-modules/*"
                "webpack:///*"      : "${webRoot}/*",                // Example: "webpack:///src/app.js"          -> "/Users/me/project/src/app.js"
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
