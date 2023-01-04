$animals = "dog","cat"

ForEach ($a in $animals) {
  Write-Output "$a"
}

# the above is equivalent to
for ($i = 0; $i -lt $animals.Count; $i++) {
  Write-Output "$($animals[$i])"
}

# equivalent to
$animals | ForEach-Object { Write-Output "$_" }

# you could add the `-Parallel` option
$animals | Foreach-Object -ThrottleLimit 5 -Parallel {
  Write-Output "$_"
}