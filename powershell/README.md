# PowerShell

- [More topics](#more-topics)
- [Overview](#overview)
  - [Components](#components)
  - [Language features](#language-features)
  - [Versions](#versions)
  - [Execution policy](#execution-policy)
  - [Sign a script](#sign-a-script)
- [Profiles](#profiles)
- [Help system](#help-system)
  - [Find commands](#find-commands)
  - [Get help](#get-help)
  - [Help files](#help-files)
- [Parameters](#parameters)
  - [Syntax](#syntax)
  - [`Show-Command`](#show-command)
  - [Common parameters](#common-parameters)
  - [`-passthru`](#-passthru)
- [Aliases](#aliases)
- [Modules](#modules)
  - [Import](#import)
  - [Install](#install)
  - [Find modules and commands](#find-modules-and-commands)
- [Variables](#variables)
  - [Predefined variables](#predefined-variables)
  - [Types](#types)
  - [Common operations](#common-operations)
- [Strings](#strings)
- [Arrays](#arrays)
  - [ArrayList](#arraylist)
- [Hash tables](#hash-tables)
- [Files](#files)
  - [Reading](#reading)
  - [Writing](#writing)
- [Output](#output)
- [Networking](#networking)
- [Secrets](#secrets)
- [Command line](#command-line)
  - [History](#history)
- [Quick recipes](#quick-recipes)


## More topics

- [Environment variables](./environment-variables/)
- [Parameters](./parameters//)
- [Errors](./errors/)

## Overview

### Components

- Shell
  - Similar to other shells: help system, pipeline, aliases
  - Differences:
    - PowerShell accepts and return **.NET objects**, unlike most shells that only accept and return text.
    - cmdlets are built on a common runtime (.NET)
    - Many types of commands: native executables, cmdlets, functions, scripts or aliases
- Scripting
  - Built-in support for common data formats like CSV, JSON and XML
- Configuration management
  - PowerShell Desired State Configuration (DSC), manage infrastructure with configuration as code

### Language features

- **Case insensitive**, eg. `Write-Output` is the same as `write-output`
- Works in the mid-ground between compiled and interpreted languages:
  - First, code is compiled into an AST in memory
  - The AST is checked for major issues
  - If everything is OK, it is run without the need for a compiled executable program

### Versions

|                        | PowerShell                                   | Windows PowerShell                           |
| ---------------------- | -------------------------------------------- | -------------------------------------------- |
| OS                     | Windows, Mac, Linux                          | a component of Windows OS                    |
| Version                | v6, v7                                       | v5                                           |
| Executable             | `pwsh.exe`                                   | `powershell.exe`                             |
| `$env:PSModulePath`    | including module paths of Windows PowerShell | -                                            |
| `$PSHOME`              | `C:\Program Files\PowerShell\7`              | `C:\Windows\System32\WindowsPowerShell\v1.0` |
| Profiles               | `$HOME\Documents\PowerShell`                 | `$HOME\Documents\WindowsPowerShell`          |
| Windows PowerShell ISE | No                                           | Yes                                          |

Most cmdlets work on either platform.

Use `$PSVersionTable` to determine the version:

```powershell
$PSVersionTable

# Name                           Value
# ----                           -----
# PSVersion                      7.2.8
# PSEdition                      Core
# GitCommitId                    7.2.8
# OS                             Microsoft Windows 10.0.19044
# Platform                       Win32NT
# PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
# PSRemotingProtocolVersion      2.3
# SerializationVersion           1.1.0.1
# WSManStackVersion              3.0
```

### Execution policy

A safety feature that prevent the execution of malicious scripts.

It's not a security feature that restricts user actions, could always be bypassed with `Powershell.exe -ExecutionPolicy ByPass`

Available policies:

- `AllSigned`: all scripts must be signed by a trusted publisher, including scripts that you write on the local computer
- `Default`: `Restricted` for Windows client and `RemoteSigned` for Windows servers
- `RemoteSigned`: require signatures for scripts downloaded from the internet, not the ones on the local computer
- `Restricted`: allow individual commands, not scripts
- `Unrestricted`: the default policy for non-Windows

```powershell
Get-ExecutionPolicy

# Set the policy
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
```

### Sign a script

```powershell
$cert =  Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert
Set-AuthenticodeSignature -FilePath "C:\Scripts\MyScript.ps1" -Certificate $cert
```


## Profiles

A profile is a script that runs when PowerShell starts. You could customize environment variables with it.

Usual profile file locations:

| Description            | Path                                                                 |
| ---------------------- | -------------------------------------------------------------------- |
| All users, any host    | `$PSHOME\Profile.ps1`                                                |
| All users, console     | `$PSHOME\Microsoft.PowerShell_profile.ps1`                           |
| All users, ISE         | `$PSHOME\Microsoft.PowerShellISE_profile.ps1`                        |
| Current user, any host | `$Home\[My ]Documents\PowerShell\Profile.ps1`                        |
| Current user, console  | `$Home[My ]Documents\PowerShell\Microsoft.PowerShell_profile.ps1`    |
| Current user, ISE      | `$Home[My ]Documents\PowerShell\Microsoft.PowerShellISE_profile.ps1` |

- "Host" here means the application hosting your current PowerShell session, PowerShell console and ISE are different hosts:

    ```powershell
    # In console
    (Get-Host).Name
    # ConsoleHost

    # In ISE (Integrated Scripting Environment)
    (Get-Host).Name
    # Windows PowerShell ISE Host
    ```

- The `$PROFILE` variable is an object that stores all the profile paths for current host. By default, there's no profile files, you could create one and put your customizations in it.

  ```powershell
  # shows profile file location for current host, current user
  $PROFILE

  # show all profile file locations
  $PROFILE | Select-Object *

  # create a profile file
  New-Item -Path $Profile.CurrentUserCurrentHost
  ```

- ISE loads its own set of profiles

    ```powershell
    $profile | Select-Object *

    # AllUsersAllHosts       : C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1
    # AllUsersCurrentHost    : C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1
    # CurrentUserAllHosts    : C:\Users\Gary Li\Documents\WindowsPowerShell\profile.ps1
    # CurrentUserCurrentHost : C:\Users\Gary Li\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1
    ```


## Help system

### Find commands

```powershell
# find commands
Get-Command *file*

# Or, use alias gcm
gcm *file*

# find commands in specified modules
gcm '*file*' -Module Microsoft.PowerShell.*

# find commands that could work on parameters of "Process" type
gcm -ParameterType Process
# CommandType     Name                 Version    Source
# -----------     ----                 -------    ------
# Cmdlet          Get-Process          3.1.0.0    Microsoft.PowerShell.Management
# Cmdlet          Stop-Process         3.1.0.0    Microsoft.PowerShell.Management

# you can also use Get-Help to find commands, which matches against both command name and help text
Get-Help *dns*
```

### Get help

```powershell
# get help for a command
help ls

# same as
Get-Help Get-ChildItem

# show examples
Get-Help Get-ChildItem -Examples

# show more details
Get-Help Get-ChildItem -Details

# show help in a separate window
Get-Help Get-ChildItem -ShowWindow

# open help in a browser
Get-Help Get-ChildItem -Online

# download help files, otherwise only summary help is available locally
Update-Help
```

### Help files

There are `about_` help files, containing general PowerShell concepts and topics, could be accessed with:

```powershell
Get-Help about*

# Name                              Category  Module                    Synopsis
# ----                              --------  ------                    --------
# about_PSFzf                       HelpFile
# about_az                          HelpFile                            about_Az
# ...
# about_Foreach-Parallel            HelpFile
# about_InlineScript                HelpFile
# about_Parallel                    HelpFile
# about_Sequence                    HelpFile

Get-Help about_az
```


## Parameters

A parameter could be either required or optional

### Syntax

- Parameter name could be omitted if it's positional, eg. `Get-ChildItem -Path C:\` is the same as `Get-ChildItem C:\`
- Some parameters accept multiple values: `Get-ChildItem -Path "C:\Users\Gary Li",D:`
  - use comma to separate them
  - enclose a value in quotation marks if it has whitespace in it

### `Show-Command`

```powershell
Show-Command Get-ChildItem
```

This opens a window, allowing you to discover parameter sets and parameters

### Common parameters

Some common parameters:

- Verbose
- Debug
- WarningAction
- WarningVariable
- ErrorAction
- ErrorVariable
- OutVariable
- OutBuffer

### `-passthru`

Forces Windows PowerShell to go ahead and pass newly created or modified objects instead of hiding them.

```powershell
Start-Process notepad

# only output result with `-PassThru`
Start-Process notepad -PassThru

# Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
# -------  ------    -----      -----     ------     --  -- -----------
#      18       3      452        860       0.08   1256   2 notepad
```


## Aliases

Common aliases:

```powershell
Get-Alias

# CommandType     Name                                               Version    Source
# -----------     ----                                               -------    ------
# Alias           % -> ForEach-Object
# Alias           ? -> Where-Object
# Alias           cat -> Get-Content
# Alias           cd -> Set-Location
# Alias           clear -> Clear-Host
# Alias           cp -> Copy-Item
# Alias           diff -> Compare-Object
# Alias           dir -> Get-ChildItem
# Alias           echo -> Write-Output
# Alias           history -> Get-History
# Alias           ls -> Get-ChildItem
# Alias           man -> help
# Alias           mv -> Move-Item
# Alias           rm -> Remove-Item
# Alias           rmdir -> Remove-Item
# Alias           tee -> Tee-Object
# Alias           wget -> Invoke-WebRequest
# Alias           where -> Where-Object
```

Define or delete an alias

```powershell
New-Alias tf terraform

# you need to use the "Alias" drive to remove an alias
Remove-Item Alias:\tf
```


## Modules

A modules is a package that contains PowerShell members, such as cmdlets, providers, functions, workflows, variables and aliases.

### Import

- If a module is in `$env:PSModulePath`, it is automatically imported when you call any commands in the module.
- Otherwise, use `Import-Module` cmdlet
- `$PSModuleAutoloadingPreference` controls the auto loading behavior

### Install

`PowerShellGet` module contains cmdlets for finding and installing modules/scripts from the "PowerShell Gallery" repository, such as
- It uses NuGet to interact with PowerShell Gallery
- Common cmdlets:
  - `Find-Module`
  - `Find-Script`
  - `Install-Module`


```powershell
Install-Module AzureADPreview
```

In some scenarios, you may want to install a module to a custom location:

```powershell
Find-Module -Name 'XXX' -Repository 'PSGallery' | Save-Module -Path 'E:\Modules'
```

Then you could either

- Import with a fully qualified name

  ```powershell
  Import-Module -FullyQualifiedName 'E:\Modules\XXX'
  ```

- Or add the custom location to the `$env:PSModulePath`

  ```powershell
  $env:PSModulePath = "E:\Modules;" + $env:PSModulePath
  ```

### Find modules and commands

```powershell
# list modules already imported into the session
Get-Module

# list all modules installed with `Install-Module` (from PowerShellGet)
# if you are using PowerShell, modules in `WindowsPowerShell` folders won't show up
Get-InstalledModule

# list all modules in `$env:PSModulePath`
# they could be imported into current session with `Import-Module`
# even when you are in PowerShell, modules in `WindowsPowerShell` folders may show up
# if they are in `$env:PSModulePath`
Get-Module -ListAvailable

# find commands in a module
Get-Command -Module Microsoft.PowerShell.Management
```


## Variables

### Predefined variables

`$true`, `$false`, `$null` are predefined variables

```powershell
# list all variables by querying the Variable: drive
Get-ChildItem Variable:
```

### Types

- String
- Int
- Double
- DateTime
- Bool

Types are usually determined dynamically based on the value

```powershell
$num = 2
$num.GetType()

# IsPublic IsSerial Name                                     BaseType
# -------- -------- ----                                     --------
# True     True     Int32                                    System.ValueType
```

you could also assign a type explicitly:

```powershell
[Double]$num = 2
$num.GetType()

# IsPublic IsSerial Name                                     BaseType
# -------- -------- ----                                     --------
# True     True     Double                                   System.ValueType
```

### Common operations

```powershell
# to unset a variable
$var = $null
```

Get properties and methods of a variable

```powershell
$str = "hello"

$str | Get-Member
```


## Strings

```powershell
$Name="Gary"

# single quote, no interpretation
Write-Host 'My name is $Name'
# My name is $Name

# double quote, backtick for escaping
Write-Host "`$Name is $Name"
# $Name is Gary

# use $() for an expression
Write-Host "`$Name has $($Name.length) characters"
# $Name has 4 characters
```


## Arrays

```powershell
# an empty array
$arr1 = @()

# an array with three strings
$arr2 = "dog","cat","parrot"

# an array with three numbers
$arr3 = 1,9,30

# an array of DirectoryInfo objects
$arr4 = Get-ChildItem

# properties/methods of each item
$arr2 | Get-Member

# properties/methods of the array
Get-Member -InputObject $arr2
```

### ArrayList

An array has a fixed size, if you add an item, a new array is created.

An arrayList doesn't have a fixed size, you could add/remove items more efficiently

```powershell
[System.Collections.ArrayList]$arr = "dog","cat","parrot"
$arr.Remove('parrot')
$arr.Add('fish')
```


## Hash tables

```powershell
$pets = @{ "cat" = "white"; "dog" = "brown" }

$pets['cat']
```


## Files

```powershell
# list items, you could use its alias `ls`
Get-ChildItem

# Show size in MB
ls | select Name, @{n="MB";e={$_.length/1MB}}

# create a directory
New-Item -ItemType Directory testFolder

# create a file with initial content
New-Item -ItemType File a.txt -Value "hello world"
```

### Reading

```powershell
# read lines in a file to an array
$lines = Get-Content ./foo.txt

# read only the last 3 lines
$last3Lines = Get-Content ./foo.txt -Tail 3
```

Read files of other formats:

- `$users = Get-Content .\Users.json | ConvertFrom-Json`: read JSON files
- `$users = Import-Csv .\Users.csv`: read CSV data to an array of objects
- `Import-Clixml`: read XML files

### Writing

Use `Out-File` to output text to a file, you could also use `>`, `>>`, as in Bash

```powershell
echo "hello world" | Out-File "myFile.txt"

echo "append this line" >> "myFile.txt"
```

To convert data to other formats before writing:

- `ConvertTo-Csv`, `Export-Csv`
- `ConvertTo-Clixml`, `Export-Clixml`
- `ConvertTo-Json`, no `Export-` version
- `ConvertTo-Html`, put objects in an HTML table, you could customize with `-Head`, `-Title`, `-PreContent`, `-PostContent`

Example:

```powershell
Get-Service | ConvertTo-Csv | Out-File Services.csv
```

`Export-Csv` combines `ConvertTo-Csv` and `Out-File`, the above is equivalent to

```powershell
Get-Service | Export-Csv Services.csv
```


## Output

Apart from writing data to a file, there are other ways to output data:

- `Out-Host`, this is the default output option, which displays everything
- `Out-Host -Paging`, displays one page at a time
- `Out-GridView`, displays objects in a separate window, like a Excel spreadsheet, you could sort/filter/copy data
- `Out-Printer`, send to printer


## Networking

```sh
# DNS lookup
nslookup google.com

# check connection to a port
Test-NetConnection 192.168.1.3 -Port 22
```


## Secrets

- Use `Read-Host "Your secret" -AsSecureString`

- Use `Get-Credential` to collect username and password, many cmdlets accept a credential parameter

  ```powershell
  $cred = Get-Credential
  Set-ADUser -Identity $user -Department "Marketing" -Credential $cred
  ```

- Use `Microsoft.PowerShell.SecretManagement` module, which works with
  - KeePass
  - LastPass
  - CredMan
  - Azure KeyVault


## Command line

### History

Two types if command history:

- In a session
  - Each session has its own history
  - Work with `Get-History`, `Clear-History`
- `PSCommandLine` history
  - Works across sessions that have the module loaded
  - Saved at `(Get-PSReadLineOption).HistorySavePath`


## Quick recipes

- Select items from a list interactively

  ```powershell
  $selection = $users | Out-GridView -PassThru
  ```
