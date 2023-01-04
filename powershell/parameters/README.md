## Simple

Parameter definition could be as simple as

```powershell
Param(
  $Name
)

Write-Host "Name is $Name"
```

`$Name` is optional here, you could run the script with or without it, parameter name is optional as well:

```powershell
.\simple.ps1
.\simple.ps1 gary
.\simple.ps1 -Name gary
```

Unnamed parameters can be accessed by `$args`

## Decorators

You could add decorators to the parameter, specifing properties:
  - optional or mandatory
  - help message
  - value type
  - default value

```powershell
Param(
  [Parameter(Mandatory, HelpMessage = "Please provide your name")]
  [string]$Name,
  [int]$Age = 20
)

Write-Host "$Name is $Age years old"
```

`$Name` is mandatory, you will be prompted, `$Age` is optional

```powershell
.\decorators.ps1
.\decorators.ps1 -Age 15
```