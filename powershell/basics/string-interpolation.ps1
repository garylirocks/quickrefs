$Name="Gary"

# single quote, no interpretation
Write-Host 'My name is $Name'

# double quote, backtick for escaping
Write-Host "`$Name is $Name"

# use $() for an expression
Write-Host "`$Name has $($Name.length) characters"