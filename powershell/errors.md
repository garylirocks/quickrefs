## `$Error`

PowerShell stores errors in the `$Error` array, the most recent one is always `$Error[0]`


## `$ErrorActionPreference`

A built-in, global variable, determins what to do when a non-terminating error occurs.

Possible values:
- `Continue` (default)
- `SilentlyContinue`
- `Inquire`
- `Stop`


## `-ErrorAction`

`-ErrorAction` is a common parameter, the value `Stop` stops the execution of the script if an error occurs, overriding `$ErrorActionPreference`

```powershell
Get-Content './file.txt' -ErrorAction Stop
Get-Content './errors.md' -Last 3
```

## Throw

```powershell
Try {
   If ($Path -eq './forbidden')
   {
     Throw "Path not allowed"
   }
   # Carry on.
} Catch {
   Write-Error "$($_.exception.message)" # Path not allowed.
}
```

## Try-Catch-Finally

```powershell
Try {
   # Do something with a file.
} Catch [System.IO.IOException] {
  # The error object can be accessed by $_.exception
  Write-Host "Something IO went wrong: $($_.exception.message)"
}  Catch {
   # Catch all. It's not an IOException but something else.
} Finally {
   # Clean up resources.
}
```


## Advanced script output

If you've configured your script as an advanced script by using `CmdletBinding)` in the `Param()` block, you can also use the cmdlets in the following list in your script for troubleshooting.

- `Write-Verbose`: Text specified by `Write-Verbose` is displayed only when you use the `-Verbose` parameter when running the script. The value of `$VerbosePreference` specifies the action to take after the `Write-Verbose` command. The default action is `SilentlyContinue`
- `Write-Debug`: Text specified by `Write-Debug` is displayed only when you use the `-Debug` parameter when running the script. The value of `$DebugPreference` specifies the action to take after the `Write-Debug` command. The default action is `SilentlyContinue`, which displays no information to screen. You need to change this action to `Continue` so that debug messages are displayed.
