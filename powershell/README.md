# PowerShell

- [More topics](#more-topics)
- [Overview](#overview)
  - [Components](#components)
  - [Language features](#language-features)
  - [Execution policy](#execution-policy)
- [Profiles](#profiles)
- [Common commands](#common-commands)
- [Customize output](#customize-output)
  - [Filtering](#filtering)
  - [Examples](#examples)
- [Modules](#modules)
  - [Import](#import)
  - [Inspect](#inspect)
- [Strings](#strings)
- [Files](#files)
- [Networking](#networking)


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


### Execution policy

On Windows, you could set execution policy to restrict what kind of scripts can be run on the machine.

```powershell
# after this, current user can only run signed scripts
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser
```

## Profiles

A profile is a script that runs when PowerShell starts. You could customize environment variables with it.

Usual profile file locations:

| Description                          | Path                                                                 |
| ------------------------------------ | -------------------------------------------------------------------- |
| All users, all hosts                 | `$PSHOME\Profile.ps1`                                                |
| All users, current host - console    | `$PSHOME\Microsoft.PowerShell_profile.ps1`                           |
| All users, current host - ISE        | `$PSHOME\Microsoft.PowerShellISE_profile.ps1`                        |
| Current user, all hosts              | `$Home\[My ]Documents\PowerShell\Profile.ps1`                        |
| Current user, current host - console | `$Home[My ]Documents\PowerShell\Microsoft.PowerShell_profile.ps1`    |
| Current user, current host - ISE     | `$Home[My ]Documents\PowerShell\Microsoft.PowerShellISE_profile.ps1` |

- "Host" here means the application hosting your current PowerShell session, PowerShell console and ISE are different hosts, :

  - In Console

    ```powershell
    (Get-Host).Name
    # ConsoleHost
    ```

  - In ISE (Integrated Scripting Environment)

    ```powershell
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


## Common commands

Versions

```powershell
# show versions/editions of powershell, os, CLR, ...
$PSVersionTable

# or just powershell version
$PSVersionTable.PSVersion

# only major version
$PSVersionTable.PSVersion.Major
```

Find commands

```powershell
# find commands
Get-Command *file*

# find commands in specified modules
Get-Command '*file*' -Module Microsoft.PowerShell.*

# find commands that could work on parameters of "Process" type
Get-Command -ParameterType Process
# CommandType     Name                 Version    Source
# -----------     ----                 -------    ------
# Cmdlet          Get-Process          3.1.0.0    Microsoft.PowerShell.Management
# Cmdlet          Stop-Process         3.1.0.0    Microsoft.PowerShell.Management
```

Get help

```powershell
# get help for a command
help ls

# same as
Get-Help Get-ChildItem

# show examples
Get-Help Get-ChildItem -Examples

# show more details
Get-Help Get-ChildItem -Details

# get online help
Get-Help Get-ChildItem -Online

# download help files, otherwise only summary help is available locally
Update-Help
```

Modules

```powershell
Get-Module

Install-Module AzureADPreview
```


## Customize output

When output an object, if there is a registered view for the object type, it is used, which likely does not include all properties of the object.

```powershell
$p=Get-Process powershell
$p

# Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
# -------  ------    -----      -----     ------     --  -- -----------
#     604      30   189008     203916       2.75  16040   4 powershell
```

You can inspect the object, to see what properties and methods exist

```powershell
# inspect the object
$p | Get-Member

#    TypeName: System.Diagnostics.Process

# Name                       MemberType     Definition
# ----                       ----------     ----------
# Handles                    AliasProperty  Handles = Handlecount
# ...
# Kill                       Method         void Kill()
# ...
```

And customize the output with `Select-Object`

```powershell
# show all properties
$p | Select-Object -Property *

# show selected properties
$p | Select-Object -Property Id,ProcessName

#    Id ProcessName
#    -- -----------
# 11392 powershell
```

### Filtering

Some cmdlet has filtering built-in, this is most efficient

```powershell
Get-ChildItem -Filter gary.* | Select-Object Name

# Name
# ----
# gary.txt
```

If not, you could use `Where-Object`

```powershell
Get-ChildItem | Where-Object Name -Like gary*

# equivalent to
Get-ChildItem | Where-Object -Property Name -Like -Value gary*

# or you could use a script block
Get-ChildItem | Where-Object {$_.Name -Like 'gary*'}
```

### Examples

- Filter with `Where-Object`, sort with `Sort-Object`, limit with `Select-Object`

  ```powershell
  ls | Where-Object {$_.Name -like '*.txt'} `
    | Sort-Object -Property Name -Descending `
    | Select-Object -First 2 -Property Name

  # Name
  # ----
  # zoe.txt
  # jack.txt
  ```

- Output as a list instead of a table

  ```powershell
  ls | Select-Object Name | Format-List

  # Name : gary.txt
  # Name : jack.txt
  # Name : zoe.txt
  ```


## Modules

A modules is a package that contains PowerShell members, such as cmdlets, providers, functions, workflows, variables and aliases.

### Import

- If a module is in `$env:PSModulePath`, it is automatically imported when you call any commands in the module.
- Otherwise, use `Import-Module` cmdlet
- `$PSModuleAutoloadingPreference` controls the auto loading behavior

### Inspect

```powershell
# list modules already imported into the session
Get-Module

# list all installed modules
Get-Module -ListAvailable

# find commands in a module
Get-Command -Module Microsoft.PowerShell.Management
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

## Files

```powershell
# list items, you could use its alias `ls`
Get-ChildItem

# create a directory
New-Item -ItemType Directory testFolder

# create a file with initial content
New-Item -ItemType File a.txt -Value "hello world"
```


## Networking

```sh
# DNS lookup
nslookup google.com

# check connection to a port
Test-NetConnection 192.168.1.3 -Port 22
```

