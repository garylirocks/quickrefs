# create
Write-Host 'Set MY_COLOR'
New-Item -Path Env:\MY_COLOR -Value 'green'

# update
Write-Host 'Update'
Set-Item -Path Env:\MY_COLOR -Value 'red'
Get-Item -Path Env:\MY_COLOR

# delete
Remove-Item -Path Env:\MY_COLOR -Verbose

if ($Env:MY_COLOR -eq $null)
{
  Write-Host "MY_COLOR is deleted"
}
