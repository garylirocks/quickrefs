# Samba

- [Ubuntu sharing methods](#ubuntu-sharing-methods)
- [Right-click Sharing](#right-click-sharing)
- [Samba via CLI](#samba-via-cli)
- [Command line tools](#command-line-tools)
  - [Samba user management](#samba-user-management)

Refs:

- [Ubuntu Samba Server Guide][ubuntu-samba-server-guide]

## Ubuntu sharing methods

There are several ways to do sharing on Ubuntu:

- **Personal File Sharing**: uses Apache to offer WebDAV-based file sharing [ref][howtogeek]

- **Right-click Sharing**: based on Samba, the definitions are saved in `/var/lib/samba/usershares/`, not visible in `smb.conf`, this method is easier to work with because:

  1. Shares are public (browserable in Network);
  2. A password is not set for shares (can be mounted by anyone)

- **Samba via CLI**: edit the `smb.conf` file and run `smbd`

- **Samba GUI tool**: install by `sudo apt-get install system-config-samba`, it will update conf files `smb.conf`, `smbusers` in `/etc/samba`

## Right-click Sharing

![Object](images/samba_share-folder.png)

## Samba via CLI

[Ubuntu Samba via CLI Tutorial][samba-via-cli]

Config user and password:

```sh
sudo smbpasswd -a gary
#    New SMB password:
#    Retype new SMB password:
#    Added user gary.

sudo pdbedit -L
#    nobody:65534:nobody
#    gary:1000:Gary Li
```

Global section:

```
[global]
    security = user
    encrypt passwords = true
    map to guest = bad user
    guest account = nobody
```

- `security = user` restricts logins to users on your server.
- `encrypt passwords = true` is necessary for most modern versions of Windows to login to your shares.
- `map to guest = bad user` will map login attempts with bad user names to the guest account you specify with `guest account = nobody`. That is, if you attempt to login to the share with a user name not set up with smbpasswd the you will be logged in as the user nobody.

Private share

```
[private]
    comment = Private Share
    path = /path/to/share/point
    browseable = no
    read only = no
```

- `browseable = no` will have the share not show up when users browse the network, **specify the path when trying to access**
- `read only = no` will let you, as an authenticated user, write to the share.

Public share

```
[public]
    comment = Public Share
    path = /path/to/share/point
    read only = no
    guest only = yes
    guest ok = yes
```

to allow samba to follow symbolic links, add the following two settings to `smb.conf`

```
# whether allow follow symlinks
wide links = yes
# whether implements CIFS UNIX extension
unix extensions = no
```

## Command line tools

```
smb.conf (5)         - The configuration file for the Samba suite
smbd (8)             - server to provide SMB/CIFS services to clients
smbstatus (1)        - report on current Samba connections
smbtree (1)          - A text based smb network browser
smbclient (1)        - ftp-like client to access SMB/CIFS resources on servers
```

server status:

```sh
sudo smbstatus

# smb network browser
smbtree

# access a network endpoint
smbclient -U gary '\\UBUNTU\share'
```

### Samba user management

```
smbpasswd (5)        - The Samba encrypted password file
smbpasswd (8)        - change a user's SMB password
pdbedit (8)          - manage the SAM database (Database of Samba Users)
```

Another command `samba-tool` is used only when you setup Samba for Active Directory

- `pdbedit` is added in **newer** version of Samba, but can only be used by root, user credentials are saved at `/var/lib/samba/private/passdb.tdb`
- `smbpasswd` is the traditional utility, can by used by none-root users to change their own password

Use `pdbedit` to list all Samba users

```sh
sudo pdbedit -L
```

[ubuntu-samba-server-guide]: https://help.ubuntu.com/community/Samba/SambaServerGuide
[howtogeek]: http://www.howtogeek.com/116309/use-ubuntus-public-folder-to-easily-share-files-between-computers/
[samba-via-cli]: https://help.ubuntu.com/community/How%20to%20Create%20a%20Network%20Share%20Via%20Samba%20Via%20CLI%20%28Command-line%20interface/Linux%20Terminal%29%20-%20Uncomplicated,%20Simple%20and%20Brief%20Way!
