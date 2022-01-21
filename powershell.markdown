# PowerShell

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

Help

```powershell
# find commands
Get-Command *blob*

# find commands in Azure.Storage, start with 'get' and operate on blobs
Get-Command -Module Azure.Storage -Verb get* -Noun *blob*

# download help files, otherwise only summary help is available locally
Update-Help

# get help for a command
help ls

# same as
Get-Help Get-ChildItem

# show examples
Get-Help Get-ChildItem -Examples

# get online help
Get-Help Get-ChildItem -Online
```

Inspect object

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

# find commands operate on the Process type
Get-Command -ParameterType Process
# CommandType     Name                           Version    Source
# -----------     ----                           -------    ------
# Cmdlet          Debug-Process                  3.1.0.0    Microsoft.PowerShell.Management
# Cmdlet          Enter-PSHostProcess            3.0.0.0    Microsoft.PowerShell.Core
```