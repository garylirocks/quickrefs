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


## ErrorAction

`-ErrorAction` is a common parameter, the value `Stop` causes a terminating error

```powershell
Try {
   Get-Content './file.txt' -ErrorAction Stop
} Catch {
   Write-Error "File can't be found"
}
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