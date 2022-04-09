param (
    [string]
    $Color
)

# parameter checking
If ($Color -eq '')
{
  Throw "You must provide a color"
}

If ($Color -eq 'White')
{
  Write-Host "As white as snow"
} ElseIf ($Color -eq 'Red') {
  Write-Host "As red as apple"
} Else {
  Write-Host "No idea"
}