# FTP

- [`proftpd`](#proftpd)
  - [Create a ftp user and group](#create-a-ftp-user-and-group)

## `proftpd`

- By default `proftpd` use system users and passwords in `/etc/passwd` for login;
- We can create virtual ftp-only users as well, which is accomplished by using the `ftpasswd` command;

### Create a ftp user and group

1. Create the user and group, use the uid and gid of default webserver user (`33`)

   ```sh
   cd /etc/proftpd/

   # create a group
   ftpasswd --group --name ftpgroup --gid 33

   # create a user
   ftpasswd --passwd --name wordpressuser --home /var/www/wordpressuser_home/ --shell /bin/false --uid 33 --gid 33
   ```

2. Make sure the output files `ftpd.passwd` and `ftpd.group` are readable by the ProFTPD user (`proftpd` by default);

3. In the config file `/etc/proftpd/proftpd.conf`:

   ```sh
   RequireValidShell   off

   # only use the following files for auth, do not use system users (mod_auth_unix.c)
   AuthOrder mod_auth_file.c
   AuthUserFile /etc/proftpd/ftpd.passwd
   AuthGroupFile /etc/proftpd/ftpd.group
   ```

Refs:

- [ProFTPD Virtual Users][proftpd_virtual_users]
- [ProFTPD Logins and Authentication][proftpd_auth]

[proftpd_virtual_users]: http://www.proftpd.org/docs/howto/VirtualUsers.html
[proftpd_auth]: http://www.proftpd.org/docs/howto/Authentication.html
