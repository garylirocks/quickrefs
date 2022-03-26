# Linux

- [Shell](#shell)
  - [Concepts](#concepts)
- [Service management](#service-management)
  - [System V init](#system-v-init)
    - [Usage](#usage)
  - [systemd](#systemd)
    - [Usage](#usage-1)
- [Journal](#journal)
- [Update Grub default boot entry](#update-grub-default-boot-entry)

## Shell

### Concepts

[The TTY demystified](https://www.linusakesson.net/programming/tty/)

- **Terminal** hardware, connects to a mainframe or large computer

  - **TeleTypewriter** was the first kind of terminal, it's a typewriter that connects to a remote computer:

    ![terminal](image/../images/linux_terminal.png)

  - **Console** - used to mean a piece of furniture, in the computer world, a console is like:

    ![console](image/../images/linux_console.png)

- **Terminal Emulator (TTY)** emulates a terminal, in Linux, press `Ctrl+Alt+Fn` you'll be in one, type `w` command, you'll see it's run by a `tty` (`tty` comes from TeleTYpewriter);

  ![tty-model](image/../images/linux_console_model.png)

- **Pseudo-Terminal (PTY)** implemented as master/slave pairs (slave is called `pts`), used by GUI terminal and SSH;

  ![pty-model](image/../images/linux_pty_model.png)

- **Shell** a command line interpreter which is run on login, such as bash/zsh;

## Service management

### System V init

- System V is the first commercial UNIX OS, Linux borrowed the init system from it;
- `init` is the first process that starts when a computer boots, its **pid is 1**, and is the parent/ancestor of all other processes;
- `init` starts processes serially;

#### Usage

- `/etc/init.d` contains init scripts
- `/etc/rc?.d` contains links to files in `/etc/init.d`

  ```sh
  ll /etc/rc3.d/S02apache2
  # lrwxrwxrwx 1 root root 17 Dec  1  2017 /etc/rc3.d/S02apache2 -> ../init.d/apache2
  ```

  in the above example `/etc/rc3.d/S02apache2` is linked to `/etc/init.d/apache2`, it will be started in run level 3, and its startup order is `02`

- use `update-rc.d` to install or remove script links

  ```sh
  # install foobar script link, according to default levels specified in the comments of its script
  update-rc.d foobar defaults

  # disable foobar
  update-rc.d foobar disable
  ```

- you can use an init script directly or the `service` command to manage a service

  ```sh
  /etc/init.d/apache2 status

  service apache2 status
  ```

### systemd

- systemd is a replacement for System V init;
- designed to start processes in parallel to reduce boot time;
- many other improvements;
- it has already been integrated into Fedora, Arch, RedHat, CentOS and Ubuntu

#### Usage

`systemctl` should be used whenever possible

```sh
systemctl status apache2.service
```

## Journal

- `journald` is part of systemd for managing logs
- Journal is save in binary format
- Use `journalctl` to retrieve logs

```sh
# tail
journalctl -f

# show recorded system boots
journalctl --list-boots

# show kernel message log
journalctl -k

# show logs from UNIT
journalctl -u UNIT

# logs since last boot
journalctl -b

# specify output format
journalctl -o [short-iso|json|json-pretty|...]
```

## Update Grub default boot entry

If you have multi-boot in a grub menu like this:

```
Ubuntu
Memory Test
Windows 10
```

usually `Ubuntu` is the default boot entry, if you would like to change it to `Windows 10`, follow these steps:

1. Update the `GRUB_DEFAULT` in `/etc/default/grub` to `2`
1. Run `sudo update-grub`, this would update `/boot/grub/grub.cfg`
