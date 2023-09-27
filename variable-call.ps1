# Inside scripts.ps1, set a variable and print it
$my_variable = "Hello, this is a variable from the script!"
Write-Host $my_variable

# Set the variable as an output variable
echo "::set-output name=my_output::$my_variable"
