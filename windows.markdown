# Windows

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

# run a command in WSL
wsl date +%Y%m%d

# use the root user
wsl -u root
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

### Files

- Windows file system is mounted at `/mnt/` in WSL, e.g. `C:` drive is mounted at `/mnt/c/`
- To access WSL files in Windows:
  - In File Explorer, visit `\\wsl$\Ubuntu\home\gary`
  - In WSL, run `explorer.exe .`

### Git

Git comes installed with most WSL distros, you may need to install the latest version:

```sh
sudo apt-get install git
```

To use the Windows Git Credential Manager in WSL

```sh
# set as git credential helper
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager-core.exe"

# additional config for Azure DevOps
git config --global credential.https://dev.azure.com.useHttpPath true
```

### VS Code

- Install the 'Remote Development' pack in VS Code
  - This makes VS Code run in 'client-server' mode, the UI is running on Windows, the server (your code, Git, plugins, etc) are running in WSL.
- Then you could 'Open folder in WSL' (or run `code .` in a WSL command line)

