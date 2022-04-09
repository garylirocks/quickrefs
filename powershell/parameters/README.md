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

## Decorators

You could add decorators to the parameter, specifing properties:
  - optional or mandatory
  - help message
  - value type
  - default value

```powershell
Param(
  [Parameter(Mandatory, HelpMessage = "Please provide your name")]
  [string]$Name = "Gary",
  [Parameter(Mandatory, HelpMessage = "Please provide your age")]
  [int]$Age = 20
)

Write-Host "$Name is $Age years old"
```

Run it with

```powershell
.\decorators.ps1 -Name Jack -Age 33
```