# PowerShell

- [Overview](#overview)
- [Common commands](#common-commands)
- [Customize output](#customize-output)
  - [Filtering](#filtering)
  - [Examples](#examples)
- [Files](#files)
- [Networking](#networking)

## Overview

Is made of a command-line shell, a scripting language and a configuration management framework.

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


## Files

```powershell
# list items, you could use its alias `ls`
Get-ChildItem

# create a directory
New-Item -ItemType Directory testFolder

# create a file
New-Item -ItemType File a.txt
```


## Networking

```sh
# DNS lookup
nslookup google.com

# check connection to a port
Test-NetConnection 192.168.1.3 -Port 22
```
