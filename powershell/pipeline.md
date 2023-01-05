# PowerShell Pipeline

- [Overview](#overview)
- [Object Members](#object-members)
- [Formatting](#formatting)
- [`Select-Object`](#select-object)
  - [Rows](#rows)
  - [Properties](#properties)
- [Calculated properties](#calculated-properties)
- [Filtering: `Where-Object`](#filtering-where-object)
  - [Comparison operators](#comparison-operators)
  - [Basic syntax](#basic-syntax)
  - [Advanced syntax](#advanced-syntax)
  - [Performance](#performance)
  - [Examples](#examples)
- [Sorting](#sorting)
- [Grouping](#grouping)
- [Enumeration](#enumeration)
  - [Advanced techniques](#advanced-techniques)
- [Measure](#measure)


## Overview

We often use pipeline `|` to connect multiple commands. Output of one command is used as input for the next command.

- Unlike most other shells, which generate text as output, PowerShell commands generate **a collection of objects**
- A common pattern is `Get-` | `Where-` | `Set-`
- Some commonly used aliases in pipelines:

  | Cmdlet           | Alias          |
  | ---------------- | -------------- |
  | `Where-Object`   | `where`, `?`   |
  | `ForEach-Object` | `foreach`, `%` |
  | `Select-Object`  | `select`       |
  | `Sort-Object`    | `sort`         |
  | `Group-Object`   | `group`        |


## Object Members

An object usually has three types of members:
- Property
- Method
- Event

```powershell
Get-Process pwsh | Get-Member

#    TypeName: System.Diagnostics.Process

# Name                       MemberType     Definition
# ----                       ----------     ----------
# ...
# Name                       AliasProperty  Name = ProcessName
# ...
# Exited                     Event          System.EventHandler Exited(System.Object, System.EventArgs)
# OutputDataReceived         Event          System.Diagnostics.DataReceivedEventHandler OutputDataReceived(System.Object…
# ...
# Start                      Method         bool Start()
# ...
# HasExited                  Property       bool HasExited {get;}
# Id                         Property       int Id {get;}
```


## Formatting

- Formatting cmdlets

  - `Format-List`, `fl`
  - `Format-Table`, `ft`
  - `Format-Wide`, `fw`, displays one property in multiple columns
  - `Format-Custom`, requires custom XML configuration files

- Depending on the output, PowerShell uses one of the cmdlet by default, you could override it by specifying your own

Examples:

```powershell
ls | Format-Table -Property Name,Mode
# Name  Mode
# ----  ----
# a.txt -a---
# b.txt -a---
# c.jpg -a---

ls | Format-List -Property Name,Mode
# Name : a.txt
# Mode : -a---

# Name : b.txt
# Mode : -a---

# Name : c.jpg
# Mode : -a---

ls | Format-Wide -Property Name -Column 1
# a.txt
# b.txt
# c.jpg

ls | Format-Wide -Property Name -Column 3
# a.txt       b.txt       c.jpg
```


## `Select-Object`

You could use `Select-Object` to limit rows or columns

### Rows

Use parameters like `-First`, `-Last`, `-Skip`, `-Unique`

```powershell
ls | Select-Object -First 2

#     Directory: C:\Users\Gary Li\myFolder

# Mode                 LastWriteTime         Length Name
# ----                 -------------         ------ ----
# d----            1/5/2023 12:36 PM                folder1
# -a---            1/5/2023 12:56 PM             13 a.txt

ls | Select-Object -First 2 -Skip 1

#     Directory: C:\Users\Gary Li\myFolder

# Mode                 LastWriteTime         Length Name
# ----                 -------------         ------ ----
# -a---            1/5/2023 12:56 PM             13 a.txt
# -a---            1/5/2023 12:57 PM             46 b.txt
```

### Properties

Most commands won't display all properties of an object by default, you could customize which properties to display using `Select-Object`

```powershell
$p=Get-Process powershell
$p

# Handles  NPM(K)    PM(K)      WS(K)     CPU(s)     Id  SI ProcessName
# -------  ------    -----      -----     ------     --  -- -----------
#     604      30   189008     203916       2.75  16040   4 powershell

# show all properties
$p | Select-Object -Property *

# show selected properties
$p | Select-Object -Property Id,ProcessName

#    Id ProcessName
#    -- -----------
# 11392 powershell
```

## Calculated properties

In addition to built-in propertied, you could create calculated properties for objects

```powershell
Get-Process |
Select-Object -First 5 |
Select-Object Name,
              ID,
              @{n='VirtualMemory(MB)';e={$PSItem.VM / 1MB}},
              @{n='PagedMemory(MB)';e={$PSItem.PM / 1MB}}

# Name                         Id VirtualMemory(MB) PagedMemory(MB)
# ----                         -- ----------------- ---------------
# AcrobatNotificationClient 18052        259.484375         8.96875
# aesm_service               3748   2101361.0859375      3.10546875
# ApplicationFrameHost      17132  2101508.34765625     17.51171875
# armsvc                     4860       66.01171875       1.5234375
# audiodg                   13320   2101330.2578125      7.55078125
```

Note:

- `$PSItem` is the same as `$_`, representing the current object
- PowerShell understands abbreviations KB, MB, GB, TB, and PB

To format the numbers, use the `-f` operator:

```powershell

Get-Process |
Select-Object -First 5 |
Select-Object Name,
              ID,
              @{n='VirtualMemory(MB)';e={'{0:N2}' -f ($PSItem.VM / 1MB) -as [Double]}}
              @{n='PagedMemory(MB)';e={'{0:N2}' -f ($PSItem.PM / 1MB) -as [Double]}}

# Name                         Id VirtualMemory(MB) PagedMemory(MB)
# ----                         -- ----------------- ---------------
# AcrobatNotificationClient 18052            259.48            8.97
# aesm_service               3748        2101361.09            3.11
# ApplicationFrameHost      17132        2101508.35           17.51
# armsvc                     4860             66.01            1.52
# audiodg                   13320        2101329.76            7.51
```


## Filtering: `Where-Object`

Like the `where` clause in SQL, you could use `Where-Object` to filter the object collection

### Comparison operators

| Operator      | Description                   |
| ------------- | ----------------------------- |
| -eq           | Equal to                      |
| -ne           | Not equal to                  |
| -gt           | Greater than                  |
| -lt           | Less than                     |
| -le           | Less than or equal to         |
| -ge           | Greater than or equal to      |
| -like         | supports "*" and "?"          |
| -in/-contains | test presence in a collection |
| -as           | test data type                |
| -match        | regular expression            |

- *The above are case insensitive, prepend a "c" to make them case sensitive, eg. `-ceq`, `-cne`, `-clike`, `-cmatch`*
- There are also `-notlike`, `-notin`

### Basic syntax

Only work with one property, and can't use properties of a property

```powershell
Get-ChildItem | Where-Object Name -Like gary*

# equivalent to
Get-ChildItem | Where-Object -Property Name -Like -Value gary*

# THIS DOESN'T WORK
Get-ChildItem | Where-Object -Property Name.Length -gt 8
```

### Advanced syntax

Script block offers a more concise and readable syntax,
- `?` is an alias to `Where-Object`
- Use `-and`, `-or` to piece together multiple conditions
- Use `-not` to negate

```powershell
# use -and
Get-ChildItem | ? { $_.Name -Like 'gary*' -and $_.Length -gt 10 }

# properties of property
Get-ChildItem | ? { $_.Name.Length -gt 8 }

# use -not
Get-ChildItem | ? { -not $_.PSIsContainer }
```

### Performance

- Use a command's built-in filtering capabilities if possible

  ```powershell
  Get-ChildItem -Filter gary.* | Select-Object Name

  # Name
  # ----
  # gary.txt
  ```

- Filter before sort

  ```powershell
  Get-ChildItem | ? { $_.Length -eq 0 } | sort Name
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


## Sorting

```powershell
Get-Service | Select-Object -Last 6 -Property Status,Name | Sort-Object Status,Name -Descending

#  Status Name
#  ------ ----
# Running ZeroConfigService
# Running WwanSvc
# Stopped XboxNetApiSvc
# Stopped XboxGipSvc
# Stopped XblGameSave
# Stopped XblAuthManager
```

## Grouping

Two ways to group objects

- `-GroupBy` parameter for formatting cmdlets, objects need to be sorted first

  ```powershell
  Get-Service | Select-Object -First 6 | Sort-Object Status | Format-Table -GroupBy Status

  #    Status: Stopped

  # Status   Name               DisplayName
  # ------   ----               -----------
  # Stopped  AarSvc_7cb96       Agent Activation Runtime_7cb96
  # Stopped  AJRouter           AllJoyn Router Service
  # Stopped  ALG                Application Layer Gateway Service
  # Stopped  AppIDSvc           Application Identity

  #    Status: Running

  # Status   Name               DisplayName
  # ------   ----               -----------
  # Running  AdobeARMservice    Adobe Acrobat Update Service
  # Running  AESMService        Intel® SGX AESM
  ```

- `Group-Object`

  ```powershell
  Get-Service | Select-Object -First 10 | Group-Object Status

  # Count Name                      Group
  # ----- ----                      -----
  #     6 Stopped                   {AarSvc_7cb96, AJRouter, ALG, AppIDSvc…}
  #     4 Running                   {AdobeARMservice, AESMService, Appinfo, AppMgmt}`powershell
  ```


## Enumeration

```powershell
Get-Process notepad | ForEach-Object { $_.kill() }

# use "%" alias
Get-Process notepad | % { $_.kill() }
```

Frequently, you don't need to explicitly enumerate objects, the above command could be replaced with `Stop-Process` cmdlet

```powershell
Get-Process notepad | Stop-Process
```

### Advanced techniques

- Run a command multiple times

  ```powershell
  1..10 | % { Get-Random }
  ```

  *`..` is the range operator*


## Measure

Gets measurements of a numeric property, returns an object which includes "Count" and other specified properties:

```powershell
Get-ChildItem -File | Measure-Object -Property Length -Sum -Average -Min -Max

# Count             : 3
# Average           : 19.6666666666667
# Sum               : 59
# Maximum           : 46
# Minimum           : 0
# StandardDeviation :
# Property          : Length
```