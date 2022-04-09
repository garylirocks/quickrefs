# define
[Environment]::SetEnvironmentVariable('MY_COLOR', 'green')
[Environment]::GetEnvironmentVariable('MY_COLOR')

# update
[Environment]::SetEnvironmentVariable('MY_COLOR', 'red')
[Environment]::GetEnvironmentVariable('MY_COLOR')

# delete
[Environment]::SetEnvironmentVariable('MY_COLOR', '')

if ($Env:MY_COLOR -eq $null)
{
  Write-Host "`$Env:MY_COLOR is deleted"
}
