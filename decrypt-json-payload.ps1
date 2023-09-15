# Load the environment variables
$git_token = $env:token
$fileContent = $env:jsonInput

$firstobjectname = $env:firstobject
$firstitterateobjectname = $env:firstitterateobject

# Specify the fields you want to decrypt
$fieldsToDecrypt = $env:fieldsToDecrypt -split ","
$decryptedJsonObject = $fileContent | ConvertFrom-Json  # Create a copy of the original JSON object

try {
    # Decryption key (use the same key you used for encryption)
    $keyHex = $env:key

    # Create a new AES object with the specified key and AES mode
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256  # Set the key size to 256 bits for AES-256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    # Loop through the specified fields and decrypt their values
    foreach ($field in $fieldsToDecrypt) {
        Write-Host "Decrypting field: $field"

        # Loop through credentials
        foreach ($entry in $decryptedJsonObject.$firstitterateobjectname) {
            Write-Host "Entered into 2nd for each...!"
            if ($entry.$field) {
                $encryptedValueBase64 = $entry.$field.EncryptedValue
                $IVBase64 = $entry.$field.IV

                if (![string]::IsNullOrEmpty($IVBase64)) {
                    # Convert IV and encrypted value to bytes
                    $IV = [System.Convert]::FromBase64String($IVBase64)
                    $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

                    # Create a decryptor with the specified IV
                    $decryptor = $AES.CreateDecryptor($AES.Key, $IV)

                    # Decrypt the data
                    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
                    $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

                    # Update the copied JSON object with the decrypted value
                    $entry.$field = $decryptedText
                } else {
                    Write-Host "IV is missing for $field. Skipping decryption."
                }
            }
        }
    }

    # Convert the entire updated JSON object back to JSON format
    $updatedJsonContent = $decryptedJsonObject | ConvertTo-Json -Depth 10

    # Display the updated JSON content
    Write-Host "Updated JSON Content:"
    Write-Host $updatedJsonContent

    # The rest of your code for updating the GitHub repository goes here

}
catch {
    Write-Host "An error occurred: $_"
}





















# # Load the environment variables
# $git_token = $env:token
# $fileContent = $env:jsonInput

# $firstobjectname = $env:firstobject
# $firstitterateobjectname = $env:firstitterateobject

# # Specify the fields you want to decrypt
# $fieldsToDecrypt = $env:fieldsToDecrypt -split ","

# try {
#     # Parse the JSON content into a PowerShell object
#     $jsonObject = $fileContent | ConvertFrom-Json

#     # Decryption key (use the same key you used for encryption)
#     $keyHex = $env:key

#     # Create a new AES object with the specified key and AES mode
#     $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
#     $AES.KeySize = 256  # Set the key size to 256 bits for AES-256
#     $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
#     $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

#     # Loop through the specified fields and decrypt their values
#     foreach ($field in $fieldsToDecrypt) {
#         Write-Host "Decrypting field: $field"

#         # Loop through credentials
#         foreach ($firstitterateobjectname in $jsonObject.$firstobjectname) {
#             Write-Host "Entered into 2nd for each...!"
#             if ($firstitterateobjectname.$field) {
#                 $encryptedValueBase64 = $firstitterateobjectname.$field.EncryptedValue
#                 $IVBase64 = $credential.$field.IV

#                 if (![string]::IsNullOrEmpty($IVBase64)) {
#                     # Convert IV and encrypted value to bytes
#                     $IV = [System.Convert]::FromBase64String($IVBase64)
#                     $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

#                     # Create a decryptor with the specified IV
#                     $decryptor = $AES.CreateDecryptor($AES.Key, $IV)

#                     # Decrypt the data
#                     $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
#                     $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

#                     # Update the JSON object with the decrypted value
#                     $firstitterateobjectname.$field = $decryptedText
#                 } else {
#                     Write-Host "IV is missing for $field. Skipping decryption."
#                 }
#             }
#         }
#     }

#     # Display the JSON object with decrypted values
#     $decrypteddata = $jsonObject | ConvertTo-Json -Depth 10
#     Write-Host "Decrypted Data:"
#     Write-Host $decrypteddata

#     # The rest of your code for updating the GitHub repository goes here

# }
# catch {
#     Write-Host "An error occurred: $_"
# }

# # Define your GitHub username, repository names, branch names, and file paths
# $githubUsername = $env:targetgithubUsername
# $repositoryName = $env:repositoryName
# $targetBranchName = $env:targetBranchName
# $targetFilePath = $env:targetFilePath


# # Define your GitHub personal access token
# $githubToken = $git_token  # Replace with your GitHub token

# # Encode the content you want to update as base64
# $updatedContent = $decrypteddata
# $updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedContent))

# # Define the API URL to fetch the file content from the source branch
# $apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$targetFilePath+"?ref="+$targetBranchName

# # Set the request headers with your personal access token
# $headers = @{
#     Authorization = "Bearer $githubToken"
#     "Content-Type" = "application/json"
# }

# # Check if the file already exists in the repository and fetch its current SHA
# $fileExists = $false
# $sha = $null
# try {
#     $fileContent = Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = "Bearer $githubToken" }
#     $fileExists = $true
#     $sha = $fileContent.sha
# }
# catch {
#     # The file doesn't exist
# }

# # Create a JSON body for the API request
# $requestBody = @{
#     "branch" = $targetBranchName  # Corrected variable name
#     "message" = "Update Decrypted Data"
#     "content" = $updatedContentBase64  # Use the base64-encoded content
#     "sha" = $sha  # Include the current SHA
# } | ConvertTo-Json

# # Determine whether to make a PUT or POST request based on whether the file exists
# if ($fileExists) {
#     # File already exists, make a PUT request to update it
#     try {
#         Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

#         Write-Host "Decrypted data has been successfully updated in $targetFilePath in branch $targetBranchName."
#     }
#     catch {
#         Write-Host "An error occurred while updating the file: $_"
#     }
# }
# else {
#     # File doesn't exist, make a POST request to create it
#     try {
#         Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

#         Write-Host "Decrypted data has been successfully created in $targetFilePath in branch $targetBranchName."
#     }
#     catch {
#         Write-Host "An error occurred while creating the file: $_"
#     }
# }
