# # Inside scripts.ps1, set a variable and print it
# $my_variable = "Hello, this is a variable from the script!"
# Write-Host $my_variable

# # Set the variable as an output variable
# echo "::set-output name=my_output::$my_variable"

# Inside variable-call.ps1, create an array of messages
$messages = @("apps is created", "developers is created", "error in kvm")

# Convert the array to a JSON string (optional, depends on your use case)
$jsonMessages = $messages | ConvertTo-Json

# Print the messages to the workflow log
Write-Host "Messages: $messages"
Write-Host "JSON Messages: $jsonMessages"

$response = Invoke-RestMethod -Uri "https://httpbin.org/get" -Method:Get -ContentType "application/json" -ErrorAction:Stop -TimeoutSec 60 -OutFile "test.json"
Write-Host "Response: $response"

# Set the messages as environment variables
Write-Host "::set-output name=MY_MESSAGES::$messages"
Write-Host "::set-output name=MY_JSON_MESSAGES::$jsonMessages"



