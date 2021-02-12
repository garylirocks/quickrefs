# tmux cheatsheet

- [Preface](#preface)
- [Session](#session)
- [Configs](#configs)
- [Vi mode](#vi-mode)
- [Panes](#panes)
- [Windows](#windows)
- [Other](#other)
- [Copy Mode](#copy-mode)

## Preface

Some useful tips for tmux

**WARNING**: _Some of the keybindings may be overridden by your `~/.tmux.conf` file_

## Session

```sh
# start tmux
tmux

# start tmux with a name
tmux new -t gary

# reassume previous session:
tmux attach

# list all sessions:
tmux ls
```

When you are in a tmux session, **`<prefix> d`** detaches it


## Configs

Personal configuration file is `~/.tmux.conf`

```sh
# change key binding prefix to `Ctrl-a`
set -g prefix C-a
```

## Vi mode

```
# change key bindings
set -g status-keys vi

setw -g mode-keys vi

# use vi's visual mode key and copy key, and pipe the content to system clipboard
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"

# syntax is different in older versions
# bind-key -t vi-copy 'v' begin-selection
# bind-key -t vi-copy 'y' copy-selection
```

## Panes

    <prefix> % 	# Split the current window into two panes
    <prefix> q 	# Show pane numbers (used to switch between panes)
    <prefix> o 	# Switch to the next pane
    <prefix> z 	# maximize a - [Preface](#preface)

    <prefix> {  	# Move current pane left
    <prefix> }  	# Move current pane right

    <prefix> <space>  	# Switch to different pane layouts

    <prefix> !          # Make current pane a new window

    <prefix> :setw synchronize-panes on/off          # broadcast command to all panes in the same window

define custom keys to switch panes quickly and with ease:

    # use alt + hjkl to select panes
    bind -n M-h select-pane -L
    bind -n M-l select-pane -R
    bind -n M-k select-pane -U
    bind -n M-j select-pane -D

## Windows

    <prefix> c 	# Create new window
    <prefix> , 	# Rename the current window
    <prefix> & 	# Kill the current window

    <prefix> w 	# List all windows
    <prefix> f 	# Find windows by name

    <prefix> p 	# Move to the previous window
    <prefix> n 	# Move to the next window
    <prefix> l 	# Move to last used window
    <prefix> <n> 	# Move to the <n>th window

## Other

    <prefix> ? 	# List all keybindings
    <prefix> : 	# Command prompt

## Copy Mode

    <prefix> [    # switch to copy mode
    # if in vi mode, use vi movement keys to move the cursor, q to quit
    <prefix> ]    # paste to tmux