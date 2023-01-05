# PowerShell Providers and Drives

- [Overview](#overview)

## Providers

A provider is an adapter that makes some data store resemble hard drives.

- Using a provider is usually more difficult than managing it by using technology-specific commands
- It offers a more consistent approach
- Some providers are only loaded after you load the relevant modules, eg. `ActiveDirectory`

List providers and capabilities:

```powershell
Get-PSProvider

# Name                 Capabilities                             Drives
# ----                 ------------                             ------
# Registry             ShouldProcess                            {HKLM, HKCU}
# Alias                ShouldProcess                            {Alias}
# Environment          ShouldProcess                            {Env}
# FileSystem           Filter, ShouldProcess, Credentials       {C, D, F, G…}
# Function             ShouldProcess                            {Function}
# Variable             ShouldProcess                            {Variable}
```

Capabilities:

- `ShouldProcess`: supports the `-WhatIf` and `-Confirm` parameters
- `Filter`: supports filtering

### Helps

- Get help about a provider: `Get-Help about_*_Provider`
- Get help about cmdlets that work with providers: `Get-Command *-Item,*-ItemProperty`


## Drives

A drive is a connection to a data store.

- Each drive uses a single PowerShell provider to connect to a data store
- Use `Get-PSDrive` to list the drives

You mostly work with cmdlets that have nouns like: `Item`, `ChildItem`, `ItemProperty`, and `Location`

```powershell
Get-Command -Noun Item | select Name

# Name
# ----
# Clear-Item
# Copy-Item
# Get-Item
# Invoke-Item
# Move-Item
# New-Item
# Remove-Item
# Rename-Item
# Set-Item

Get-Command -Noun location | select Name

# Name
# ----
# Get-Location
# Pop-Location
# Push-Location
# Set-Location
```

There are two types of path parameters to the commands:

- `-Path`: interprets asterisk (*) and question mark (?) as wildcard characters
- `-LiteralPath`: everything is literal

### Registries

Two drives are created automatically:

- **HKLM** represents **HKEY_LOCAL_MACHINE**
- **HKCU** represents **HKEY_LOCAL_USER**

```powershell
Get-ChildItem "HKCU:\Console"

Get-Item "HKCU:\Console\Git Bash"

#     Hive: HKEY_CURRENT_USER\Console

# Name                           Property
# ----                           --------
# Git Bash                       FaceName   : Lucida Console
#                                FontFamily : 54
#                                FontSize   : 917504
#                                FontWeight : 400

Get-ItemPropertyValue "HKCU:\Console\Git Bash" -Name FaceName
# Lucida Console
```

### Certificates

Two top level folders: `Cert:\CurrentUser`, `Cert:\LocalMachine`

```powershell
# get certs for SSL server authentication for "localhost"
ls Cert:\CurrentUser\My\ -DnsName localhost -SSLServerAuthentication

#    PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\My

# Thumbprint                                Subject              EnhancedKeyUsageList
# ----------                                -------              --------------------
# EE7AC1BCCA1833BCB22DF4C448BCEECE5F444889  CN=localhost         Server Authentication
# DA10750B69CCD87815CB70BD6485DAC1EC210C76  CN=localhost         Server Authentication
```