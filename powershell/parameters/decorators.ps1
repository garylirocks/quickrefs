Param(
  [Parameter(Mandatory, HelpMessage = "Please provide your name")]
  [string]$Name,
  [int]$Age = 20
)

Write-Host "$Name is $Age years old"