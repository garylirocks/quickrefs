tmux cheatsheet
===============

## Preface
Some useful tips for tmux

**WARNING**: *Some of the keybindings maybe overrided by your `~/.tmux.conf` file*

## Run

reassume previous session:

    tmux attach


## Configs

personal configuration file is `~/.tmux.conf`

change key binding prefix to `Ctrl-a`
    
    set -g prefix C-a


## Vi mode

    # change key bindings
    set -g status-keys vi

    setw -g mode-keys vi

    # use vi's visual mode key and copy key
    bind-key -t vi-copy 'v' begin-selection
    bind-key -t vi-copy 'y' copy-selection


## panes

    <prefix> % 	# Split the current window into two panes
    <prefix> q 	# Show pane numbers (used to switch between panes)
    <prefix> o 	# Switch to the next pane

    <prefix> {  	# Move current pane left
    <prefix> }  	# Move current pane right

    <prefix> <space>  	# Switch to different pane layouts

    <prefix> !          # Make current pane a new window

define custom keys to switch panes quickly and with ease:

    # use alt + hjkl to select panes
    bind -n M-h select-pane -L
    bind -n M-l select-pane -R
    bind -n M-k select-pane -U
    bind -n M-j select-pane -D


## windows
    
    <prefix> c 	# Create new window
    <prefix> , 	# Rename the current window
    <prefix> & 	# Kill the current window

    <prefix> w 	# List all windows
    <prefix> f 	# Find windows by name

    <prefix> p 	# Move to the previous window
    <prefix> n 	# Move to the next window
    <prefix> l 	# Move to last used window
    <prefix> <n> 	# Move to the <n>th window


## other

    <prefix> d 	# Detach current client

    <prefix> ? 	# List all keybindings
    <prefix> : 	# Command prompt


## Copy Mode

    <prefix> [    # switch to copy mode
    # if in vi mode, use vi movement keys to move the cursor, q to quit
    <prefix> ]    # paste to tmux



    

