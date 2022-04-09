# Environment variables

- Can be defined in three scopes:
  - System(or Machine) scope
  - User scope
  - Process scope
- Always inherited by child processes
- Always stored as a string and can't be empty (gets deleted when you assign an empty string to it)

There are multiple methods for using and managing environment variables:

- The variable syntax
- The Environment provider and Item cmdlets
- The .Net **`System.Environment`** class

## Variable syntax

Only work for process level variables

- `$Env:MY_COLOR`, `$` indicates a variable, `Env:` is the drive name
- `$Env:MY_COLOR = ''` deletes the variable, make it `$null`

## Environment provider

Use `Env:\` path with `*-Item` cmdlets

```powershell
New-Item -Path Env:\MY_COLOR -Value 'green'
Set-Item -Path Env:\MY_COLOR -Value 'red'
Remove-Item -Path Env:\MY_COLOR
```

## `System.Environment` methods

Use `[Environment]::*EnvironmentVariable` methods

```powershell
[Environment]::SetEnvironmentVariable('MY_COLOR', 'green')
[Environment]::GetEnvironmentVariable('MY_COLOR')
[Environment]::SetEnvironmentVariable('MY_COLOR', '')

# specify the 'Machine' scope
[Environment]::SetEnvironmentVariable('MY_COLOR', 'white', 'Machine')
```

## Saving changes to environment variables

Three ways

- Set it in profile file

   ```powershell
   # C:\Users\*\WindowsPowerShell\Microsoft.VSCode_profile.ps1

   $Env:Path += ";C:\Tools'
   ```

- `SetEnvironmentVariable` in `User` or `Machine` scope

   ```powershell
   [Environment]::SetEnvironmentVariable('MY_COLOR', 'red', 'Machine')
   ```

- Use System Control Panel

## Notable environment variables

- `$Env:PSModulePath`, a list of locations that are searched to find modules and resources
- `$Env:PSExecutionPolicy`
