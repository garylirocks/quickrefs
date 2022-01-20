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

# get help for a command
help ls

# alias for
Get-Help Get-ChildItem
```