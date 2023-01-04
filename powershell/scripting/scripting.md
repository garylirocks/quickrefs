# Scripting

## Functions

## Modules

To create a module

- Create a script file with `.psm1` extension, such as `GaryTest.psm1`
- Put your script file in a folder with the same name `GaryTest`
- Put the folder under `$env:PSModulePath`, such as `C:\Users\Gary Li\Documents\PowerShell\Modules\`

Then you can use functions in your module, just like other modules

## Dot sourcing

To load functions, variables into current scope, use `.`

```powershell
. C:\scripts\functions.ps1
```