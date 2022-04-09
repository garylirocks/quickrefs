
# define a process level env variable
$Env:MY_COLOR = "green"

# update
$Env:MY_COLOR = "red"

# output
$Env:MY_COLOR

# delete
$Env:MY_COLOR = ""

if ($Env:MY_COLOR -eq $null)
{
  Write-Host "`$Env:MY_COLOR is deleted"
}
