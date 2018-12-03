Linux
=======

- [Service management](#service-management)
    - [System V init](#system-v-init)
        - [Usage](#usage)
    - [systemd](#systemd)
        - [Usage](#usage)

## Service management

### System V init

* System V is the first commercial UNIX OS, Linux borrowed the init system from it;
* `init` is the first process that starts when a computer boots, its **pid is 1**, and is the parent/ancestor of all other processes;
* `init` starts processes serially;

#### Usage

* `/etc/init.d` contains init scripts
* `/etc/rc?.d` contains links to files in `/etc/init.d`

    ```sh
    ll /etc/rc3.d/S02apache2
    # lrwxrwxrwx 1 root root 17 Dec  1  2017 /etc/rc3.d/S02apache2 -> ../init.d/apache2
    ```

    in the above example `/etc/rc3.d/S02apache2` is linked to `/etc/init.d/apache2`, it will be started in run level 3, and its startup order is `02`

* use `update-rc.d` to install or remove script links

    ```sh
    # install foobar script link, according to default levels specified in the comments of its script
    update-rc.d foobar defaults

    # disable foobar
    update-rc.d foobar disable
    ```

* you can use the an init script directly or the `service` command to manage a service

    ```sh
    /etc/init.d/apache2 status

    service apache2 status
    ```

### systemd

* systemd is a replacement for System V init; 
* designed to start processes in parallel to reduce boot time;
* many other improvements;
* it has already been integrated into Fedora, Arch, RedHat, CentOS etc, in Ubuntu, needs to be installed and configured;

#### Usage

`systemctl` should be used whenever possible

```sh
systemctl status apache2.service
```