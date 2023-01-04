$name = Read-Host "Please enter your name"
Write-Output "Hello $name"

$password = Read-Host "Please enter your password" -AsSecureString
Write-Output "Password type $($password.GetType())"
