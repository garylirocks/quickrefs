# PowerShell

- [Overview](#overview)
- [Common commands](#common-commands)
- [Working with objects](#working-with-objects)
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

## Working with objects

```powershell
# show details of a returned object
Get-Process -Name *powershell* | Get-Member
#    TypeName: System.Diagnostics.Process

# Name                       MemberType     Definition
# ----                       ----------     ----------
# Handles                    AliasProperty  Handles = Handlecount
# ...

# filter result columns using 'Select-Object'
Get-Process -Name *powershell* | Get-Member | Select-Object -Property MemberType -Unique
```

## Networking

```sh
# DNS lookup
nslookup google.com

# check connection to a port
Test-NetConnection 192.168.1.3 -Port 22
```
