# Windows

- [SSH](#ssh)
- [Git](#git)
  - [Git Credential Manager](#git-credential-manager)
- [Windows Terminal](#windows-terminal)
- [WSL](#wsl)
  - [Commands](#commands)
  - [Configuration](#configuration)
  - [Files](#files)
  - [Git](#git-1)
    - [Multiple accounts for GitHub on one machine](#multiple-accounts-for-github-on-one-machine)
  - [VS Code](#vs-code)
  - [Terraform](#terraform)
- [Quick recipes](#quick-recipes)
  - [Copy files](#copy-files)

## SSH

- Linux config files are compatible on Windows, just move all files to `C:/Users/username/.ssh/`
- You could use paths like `~/.ssh/id_rsa` in the config

## Git

### Git Credential Manager

- Useful when you use HTTP protocols
- Uses Windows Credential Store to control sensitive infomation
- Is a secure Git credential helper, provides multi-factor authentication support for Azure DevOps, GitHub and Bitbucket
- Is included with Git for Windows, simple select it as the credential helper during installation

## Windows Terminal

- Allows you to run CmdLet, PowerShell, AZ CLI, WSL in different tabs
- Split tab into panes

## WSL

- WSL targets a developer audience who wants to use Linux tools.
- Requires fewer resources than a full Linux VM, allows you to access Windows files from within Linux.
- WSL 2 uses Hyper-V
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
wsl --import UbuntuNew 'C:\' my-wsl-ubuntu.tar

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

- Windows file system is mounted at `/mnt/` in WSL, e.g. `C:` drive is mounted at `/mnt/c/`
- To access WSL files in Windows:
  - In File Explorer, visit `\\wsl$\Ubuntu\home\gary`
  - In WSL, run `explorer.exe .`
- By default, WSL storage is located at `$env:LOCALAPPDATA\Packages\`

### Git

Git comes installed with most WSL distros, you may need to install the latest version:

```sh
sudo apt-get install git
```

You could use the Windows Git Credential Manager in WSL (https://github.com/GitCredentialManager/git-credential-manager/blob/main/docs/wsl.md):

- Git inside of a WSL can launch the GCM Windows application transparently to acquire credentials
- Windows stores the credentials, which could be shared by Windows applications and WSL
- Config your WSL Git like this:

  ```sh
  # set as git credential helper
  # use `git-credential-wincred.exe` if there's not `git-credential-manager-core.exe`
  git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager-core.exe"

  # By default the credential manager saves one credential per hostname
  # If your want the credential manager to save a credential for each url path, set `useHttpPath` to `true`, this allows you to have one credential per repo, meaning you can use different accounts
  git config --global credential.https://dev.azure.com.useHttpPath true
  ```

- Make Windows GCM use WSL Git config, run this in *Administrator* Command Prompt (*seems not working sometimes ?*):

  ```sh
  SETX WSLENV %WSLENV%:GIT_EXEC_PATH/wp
  ```

#### Multiple accounts for GitHub on one machine

1. Set `useHttpPath` to `false` globally, this will be the default

    ```sh
    git config --global credential.https://github.com.useHttpPath false
    ```

2. In a repo where you want to use another account, set the value to `true`, this will make the credential manager save another credential for this repo

    ```sh
    git config --local credential.https://github.com.useHttpPath true
    ```

**Seems in WSL, it won't popup the Git credential manager dialog for you to sign in, you need to do it in Windows (PowerShell, cmd)**

### VS Code

- Install the 'Remote Development' pack in VS Code
  - This makes VS Code run in 'client-server' mode, the UI is running on Windows, the server (your code, Git, plugins, etc) are running in WSL.
- Then you could 'Open folder in WSL' (or run `code .` in a WSL command line)


### Terraform

There's an issue that Terraform can't authenticate with Azure, see https://github.com/microsoft/WSL/issues/8022


## Quick recipes

### Copy files

```powershell
robocopy F:\ G:\ *.* /J /E /COPYALL /XD "System Volume Information" "$RECYCLE.BIN" /XO

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