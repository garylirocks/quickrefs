Param(
  [Parameter(Mandatory, HelpMessage = "Please provide your name")]
  [string]$Name = "Gary",
  [Parameter(Mandatory, HelpMessage = "Please provide your age")]
  [int]$Age = 20
)

Write-Host "$Name is $Age years old"