Function Get-Greeting {
  Param (
    [string]$Name
  )

  Write-Output "Hello $Name"
}

$greeting = Get-Greeting Gary
Write-Output $greeting

############
# Use Return()
############
Function Get-Greeting2 {
  Param (
    [string]$Name
  )

  $str = "Hello $Name"
  Return($str)
}

$greeting2 = Get-Greeting2 Jack
Write-Output $greeting2
