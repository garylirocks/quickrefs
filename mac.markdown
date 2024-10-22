# Mac

- [Shortcuts](#shortcuts)
  - [Command and Control](#command-and-control)
  - [Launching apps](#launching-apps)
  - [Switching apps](#switching-apps)
  - [Windows](#windows)
  - [Menus](#menus)
  - [Misc](#misc)
  - [Lock/Sleep/Power](#locksleeppower)
  - [Keyboard](#keyboard)
- [Concepts](#concepts)
  - [App organization](#app-organization)
  - [Stack](#stack)
- [Setup](#setup)
- [Homebrew](#homebrew)
- [Troubleshooting](#troubleshooting)
  - [Mouse stuttering/jittering](#mouse-stutteringjittering)
- [Cookbook](#cookbook)


## Shortcuts

### Command and Control

"Command" key is usually used for command in GUI apps.

"Control" key is used to input control sequences (eg. in terminals).

### Launching apps

- `Cmd + Space`: Spotlight search (hold for Siri)
- `Ctrl + F3`: Focus the Dock

### Switching apps

- `Cmd + Tab`: Switch applications (use "Down" key to show windows of the app)
- <code>Cmd + `</code>: Switch between windows of the same application
- `F11`: Show Desktop spaces
- `Ctrl + Up`: Show Mission control
- `Ctrl + Left/Right`: Switch Desktop space

### Windows

- `Cmd + W` close a window
- `Cmd + M` minimise a window
- `Cmd + Q` quit an app
- `Ctrl + Cmd + F` Make window full screen

You can add custom shortcuts to move a window among displays, see details [here](https://discussions.apple.com/thread/255197821)

![Custom shortcuts for moving a window](./images/mac_custom-shortcuts-move-windows-to-display.png)

### Menus

- `Ctrl + F2`: Focus menu bar
- `Ctrl + F8`: Focus status menu
- `Shift + Cmd + /`: Show help menu

### Misc

- `Ctrl + Space`: Change input source
- `Ctrl + Cmd + Space`: Show Character Viewer (emoji, symbols, etc)
- `Space` Preview selected item
- `Shift + Cmd + 5` take screenshot (change this to the screenshot key)

### Lock/Sleep/Power

- `Ctrl + Cmd + Q`: Lock screen
- `Power`: Unlock screen (Touch ID)
- `Power`: Press to go to sleep (better not use the Touch ID finger!)

### Keyboard

- For each connected keyboard, you can remap the action of modifier key (eg. use Caps Lock key for Command)
- For functions keys (F1, F2), you can control whether they perform standard functions, or do special actions by default
- In Terminal App and VS Code, you need to update settings, enable "Use Option as Meta key", there is no global settings


## Concepts

### App organization

The hierarchy is like:

Screen/Display -> Desktop/Space -> Apps -> Windows

- Each screen/display can have multiple desktops of its own
- A full-screen app occupies its own desktop/space

### Stack

On a desktop, you can group files by stack

- A group of files, by kind, date, tags, etc


## Setup

Follow steps here https://github.com/garylirocks/dotfiles/blob/master/mac-setup/README.md


## Homebrew

`brew cask` is an extension to `brew`, usually deals with GUI applications


## Troubleshooting

### Mouse stuttering/jittering

Logitech mouse connected via Unifying USB dongle doesn't work well, the cursor is lagging/jittering.

Seems **moving the dongle away from the dock** (to an USB hub extension, so less RF interference) fixed it.

See https://forums.anandtech.com/threads/logitech-wireless-mouse-stutter-here-is-the-fix.2591285


## Cookbook

- Uninstall an app: remove the app from `/Applications` folder
- Clipboard history: install "Clipy", then `Shift + Cmd + V`