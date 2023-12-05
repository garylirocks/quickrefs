# Windows

- [Shortcuts](#shortcuts)
- [SSH](#ssh)
- [Git](#git)
  - [Git Credential Manager](#git-credential-manager)
- [Windows Terminal](#windows-terminal)
- [WSL](#wsl)
  - [Commands](#commands)
  - [Configuration](#configuration)
  - [Files](#files)
  - [Git](#git-1)
    - [Credential management](#credential-management)
    - [Multiple accounts for GitHub on one machine](#multiple-accounts-for-github-on-one-machine)
  - [VS Code](#vs-code)
  - [Terraform](#terraform)
- [Docker Desktop](#docker-desktop)
- [File System](#file-system)
  - [File length](#file-length)
    - [Example `fsutil`](#example-fsutil)
    - [Example `[System.IO.FileStream]::SetLength()`](#example-systemiofilestreamsetlength)
    - [Generate a file with random bytes](#generate-a-file-with-random-bytes)
    - [Disk throughput testing](#disk-throughput-testing)
  - [Monitoring](#monitoring)
  - [Copy files](#copy-files)

## Shortcuts

- `Win`: start menu
- `Win + V`: clickboard history
- `Win + M`: minimize all windows
- `Win + D`: show/hide desktop
- `Win + X`: quick link menu
- `Win + Tab`: task view, switch between virtual desktops
- `Win + Ctrl + < or >`: switch between virtual desktops
- `Win + ?`: Shortcut guide (when enabled in PowerToys)

- `Alt + F4`: close current window
- `Shift + F10`: right-click menu (aka. context menu)


## SSH

- Linux config files are compatible on Windows, just move all files to `C:/Users/username/.ssh/`
- You could use paths like `~/.ssh/id_rsa` in the config

## Git

### Git Credential Manager

- Is a secure Git credential helper, provides multi-factor authentication support for Azure DevOps, GitHub and Bitbucket
- Is included with Git for Windows, select it as the credential helper during installation
- Uses Windows Credential Store to store credentials

## Windows Terminal

- Allows you to run CmdLet, PowerShell, AZ CLI, WSL in different tabs
- Split tab into panes

## WSL

- WSL targets a developer audience who wants to use Linux tools.
- Requires fewer resources than a full Linux VM, allows you to access Windows files from within Linux.
- WSL 2 uses Hyper-V
- A single Linux kernel is shared by multiple distros
- These tools could be used with WSL: VS Code, Git, databases, GPU acceleration, Linux GUI apps, mounting an external drive or USB

### Commands

```powershell
# show available Linux distributions
wsl --list --online

# install default distro (Ubuntu)
wsl --install

# use the root user
wsl -u root

# stop a WSL distro
wsl -t Ubuntu

# show WSL distros, state and version
wsl -l -v
#   NAME            STATE           VERSION
# * Ubuntu-20.04    Running         1

# update a distro to version 2
wsl --set-version Ubuntu-20.04 2
```

Export / Import

```powershell
# backup/export to a file
wsl --export Ubuntu my-wsl-ubuntu.tar

# import a distribution from a file
# The installation location is 'WSL' here, which needs to be a relative path, an absolute path doesn't work
wsl --import 'Ubuntu-distro' 'WSL' 'C:\Users\gary\wsl-ubuntu.tar'

# run a specified distro
wsl -d UbuntuNew

# remove a distro
wsl --unregister UbuntuNew
```

Mixing Windows and Linux commands:

- In PowerShell

  ```PowerShell
  # windows then linux command
  dir | wsl grep 'Music'

  # reverse
  wsl ls -la | findstr "git"
  ```

- In WSL

  ```sh
  # remmember the `.exe`
  ipconfig.exe | grep IPv4 | cut -d: -f2
  ```

### Configuration

To configure default behavior for a distro

- Add `wsl.conf` to the `/etc/` folder in the distro:

  ```
  [user]
  default = gary

  [network]
  generateResolvConf = false
  ```

- Restart the distro

### Files

- Within WSL:
  - Windows drives are mounted at `/mnt/` in WSL, e.g. `C:` drive is mounted at `/mnt/c/`
- Within Windows:
  - Access WSL files like `\\wsl.localhost\Ubuntu\home\gary`
  - By default, WSL storage is located at `$env:LOCALAPPDATA\Packages\`

### Git

Git comes installed with most WSL distros, you may need to install the latest version:

```sh
sudo apt-get install git
```

#### Credential management

You could use the Git Credential Manager (installed in Windows) in WSL (https://github.com/GitCredentialManager/git-credential-manager/blob/main/docs/wsl.md):

- Git inside of a WSL can launch the GCM Windows application transparently to acquire credentials (seems not work, need to do it in Windows)
- Windows stores the credentials, which could be shared by Windows applications and WSL
- Config your WSL Git like this:

  ```sh
  # set as git credential helper
  # the exact location of "git-credential-manager.exe" might be different on your system
  # !! don't use "git-credential-wincred.exe", which has issues with WSL
  git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"

  # For Azure DevOps
  # By default the credential manager saves one credential per hostname
  # If your want the credential manager to save a credential for each url path, set `useHttpPath` to `true`
  # this allows you to have one credential per repo, meaning you can use different accounts
  git config --global credential.https://dev.azure.com.useHttpPath true
  ```

- (Optional) To make GCM (in Windows) uses WSL Git config, run this in *Administrator* Command Prompt (*seems not working sometimes ?*, you could copy your WSL Git config to Windows manually):

  ```sh
  SETX WSLENV %WSLENV%:GIT_EXEC_PATH/wp
  ```

#### Multiple accounts for GitHub on one machine

1. Set `useHttpPath` to `false` globally, this will be the default, you only need to authenticate once for all repos with this account

    ```sh
    git config --global credential.https://github.com.useHttpPath false
    ```

2. In a repo where you want to use another account, set the value to `true`, this will make the credential manager save another credential for this repo, you will need to authenticate for each repo

    ```sh
    git config --local credential.https://github.com.useHttpPath true
    ```

Notes:

- In Windows, Git global config file path could be changed by setting `$Env:GIT_CONFIG_GLOBAL` in your PowerShell profile
- **Seems in WSL, it won't popup the Git credential manager dialog for you to sign in, you need to do it in Windows (PowerShell, cmd)**
- If something goes wrong
  - Go to Credential Manager, clear all GitHub credentials
  - Try `git pull` in a repo that uses the default account, it will ask you to sign in
  - Then `git pull` in a repo with the alternative account, you login in again (use a different browser, so you login to a different GitHub account)

### VS Code

- Install the 'Remote Development' pack in VS Code
  - This makes VS Code run in 'client-server' mode, the UI is running on Windows, the server (your code, Git, plugins, etc) are running in WSL.
- Then you could 'Open folder in WSL' (or run `code .` in a WSL command line)


### Terraform

There's an issue that Terraform can't authenticate with Azure, see https://github.com/microsoft/WSL/issues/8022


## Docker Desktop

- It can use WSL 2 (instead of Hyper-V) as backend
  - This allows `docker` commands in WSL to interact with it


## File System

### File length

See https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-file#remarks

In **NTFS**, there are two important concepts of file length: the end-of-file (EOF) marker and Valid Data Length (VDL)
- **EOF**: the `0x00` EOF marker at the end of the file
- **VDL**: length of valid data on disk
  - can be queried with `fsutil file [queryvaliddata] [/R] [/D] <filename>`
  - can be set with `fsutil file [setvaliddata] <filename> <datalength>` (need Administrator permission)

VDL is smaller than EOF. Any reads between VDL and EOF automatically **return 0 without actually reading the disk.**

#### Example `fsutil`

Create a 64GB file

```powershell
$sizeInGB=64
fsutil file createNew "${sizeInGB}GB.fsutil.dummyfile" $(${sizeInGB}*1024*1024*1024)

ls | select Name, @{n="GB";e={$_.length/1GB}}
# Name                  GB
# ----                  --
# 64GB.fsutil.dummyfile 64
```

This creates the file really quick, but it actually **just write EOF marker, set VDL to 0, not actually filling the file with bytes**, but it's NOT a sparse file

```powershell
fsutil file queryvaliddata 64GB.fsutil.dummyfile
# Valid Data Length is 0x0 (0)

fsutil sparse queryflag 64GB.fsutil.dummyfile
# This file is NOT set as sparse
```

VDL could be changed

```powershell
fsutil file setvaliddata .\64GB.fsutil.dummyfile 127
# Valid data length is changed

fsutil file queryvaliddata 64GB.fsutil.dummyfile
# Valid Data Length is 0x7f (127)
```

#### Example `[System.IO.FileStream]::SetLength()`

This has the same effect, just setting the VDL to 0

```powershell
$sizeInGB=64
$f = new-object System.IO.FileStream "$(pwd)\${sizeInGB}GB.setLength.dummyfile", Create, ReadWrite
$f.SetLength("${sizeInGB}GB")
$f.Close()

fsutil file queryvaliddata .\64GB.setLength.dummyfile
# Valid Data Length is 0x0 (0)
```

#### Generate a file with random bytes

```powershell
$out = new-object byte[] $(1*1024*1024*1024); # this number could not be larger than 2^32
(new-object Random).NextBytes($out);
[IO.File]::WriteAllBytes("$(pwd)\1GB.random.dummyfile", $out);
```

#### Disk throughput testing

If you want to generate a big file for testing disk throughput (eg. copying from one disk to another), if the big file's VDL is 0, it only incur write operations on the target disk, but **NOT any read operations on the source disk !!**

To workaround this, set the VDL manually to the file size:

```powershell
$sizeInGB=64
fsutil file createNew "${sizeInGB}GB.fsutil.dummyfile" $(${sizeInGB}*1024*1024*1024)

# manually set VDL to the file size
fsutil file setvaliddata "${sizeInGB}GB.fsutil.dummyfile" $(${sizeInGB}*1024*1024*1024)

fsutil file queryvaliddata "${sizeInGB}GB.fsutil.dummyfile"
# Valid Data Length is 0x1000000000 (68719476736)
```

### Monitoring

Resource Monitor could show you infos about CPU, memory, disk, network

For disks:
  - Processes reading/writing to disks
  - Disk MBps
  - Disk queue depth
  - Which files are accessed by which processes

![File system monitoring](images/windows_resource-monitor-disk.png)

### Copy files

```powershell
# copies whole source folder to destination
robocopy F:\ G:\ *.* /J /E /COPYALL /XD "System Volume Information" "$RECYCLE.BIN" /XO

# copy a specific file
robocopy D:\tempDir\ C:\tempDir\ "test.txt"

# to get help on options
robocopy /?
```

- `F:\`: old disk (source)
- `G:\`: new disk (destination);
- `*.*`: copy every file using every extension;
- `/J`: copy using unbuffered I/O;
- `/E`: include all empty sub-folders;
- `/COPYALL`: to copy all data/attributes/timestamps/DACLs/Owner info/auditing info;
- `/XD`: exclude directories matching the names on the right;
- "System Volume Information": do not robocopy the system information of the old disk, the new disk needs to build its own partition/volume information;
- "$RECYCLE.BIN": ignore recycle bin;
- `/XO`: exclude older files (files which has a newer version in destination)
