# zsh

## Config loading order

refer: [Zsh/Bash startup files loading order](https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/)

    +----------------+-----------+-----------+------+
    |                |Interactive|Interactive|Script|
    |                |login      |non-login  |      |
    +----------------+-----------+-----------+------+
    |/etc/zshenv     |    A      |    A      |  A   |
    +----------------+-----------+-----------+------+
    |~/.zshenv       |    B      |    B      |  B   |
    +----------------+-----------+-----------+------+
    |/etc/zprofile   |    C      |           |      |
    +----------------+-----------+-----------+------+
    |~/.zprofile     |    D      |           |      |
    +----------------+-----------+-----------+------+
    |/etc/zshrc      |    E      |    C      |      |
    +----------------+-----------+-----------+------+
    |~/.zshrc        |    F      |    D      |      |
    +----------------+-----------+-----------+------+
    |/etc/zlogin     |    G      |           |      |
    +----------------+-----------+-----------+------+
    |~/.zlogin       |    H      |           |      |
    +----------------+-----------+-----------+------+
    |                |           |           |      |
    +----------------+-----------+-----------+------+
    |                |           |           |      |
    +----------------+-----------+-----------+------+
    |~/.zlogout      |    I      |           |      |
    +----------------+-----------+-----------+------+
    |/etc/zlogout    |    J      |           |      |
    +----------------+-----------+-----------+------+

**Put stuff in `~/.zshrc`, which is always executed**

## Autocompletion

### SSH host autocompletion issue

when using autocomplete after `ssh` command, if there is a match in `/etc/hosts`, it is used automatically, doesn't try to match hosts in `~/.ssh/config`, which should take precedence over `/etc/hosts`

Found an answer here: [https://serverfault.com/a/170481](https://serverfault.com/a/170481), added the script to `ssh.completion.zsh`
