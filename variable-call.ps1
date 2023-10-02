# Check if summary.txt file exists, if not, create it
$filePath = "summary.txt"
if (-not (Test-Path -Path $filePath)) {
    New-Item -Path $filePath -ItemType File | Out-Null
}

# Sample data to add to the file
$sampleText = "sample text to store in the summary file to upload into the artifacts...!"

Write-Host $sampleText

# Read the existing content of the file
$fileContent = Get-Content -Path $filePath -Raw

# Append the sample data to the file content
$newContent = $fileContent + "`n" + $sampleText

# Write the updated content back to the file
$newContent | Set-Content -Path $filePath


























# # # Inside scripts.ps1, set a variable and print it
# # $my_variable = "Hello, this is a variable from the script!"
# # Write-Host $my_variable

# # # Set the variable as an output variable
# # echo "::set-output name=my_output::$my_variable"

# # Inside variable-call.ps1, create an array of messages
# $messages = @("apps is created", "developers is created", "error in kvm")

# # Convert the array to a JSON string (optional, depends on your use case)
# $jsonMessages = $messages | ConvertTo-Json

# # Print the messages to the workflow log
# Write-Host "Messages: $messages"
# Write-Host "JSON Messages: $jsonMessages"

# $response = Invoke-RestMethod -Uri "https://httpbin.org/get" -Method:Get -ContentType "application/json" -ErrorAction:Stop -TimeoutSec 60 -OutFile "test.json"
# Write-Host "Response: $response"

# # Set the messages as environment variables
# Write-Host "::set-output name=MY_MESSAGES::$messages"
# Write-Host "::set-output name=MY_JSON_MESSAGES::$jsonMessages"



