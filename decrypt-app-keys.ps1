$git_token = $env:token

# Define your GitHub username, repository names, branch name, and file path
$githubUsername = $env:sourcegithubUsername
$sourceRepo = $env:sourceRepo
$sourcebranchname = $env:sourcebranchname
$filePath = $env:filePath

# Define the GitHub API URL for fetching the file content from a specific branch
$apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$sourceRepo+"/contents/"+$filePath+"?ref="+$sourcebranchname

# Set the request headers with your PAT
$headers = @{
    Authorization = "Bearer $git_token"
}

try {
    # Make a GET request to fetch the file content
    $fileContent = Invoke-RestMethod $apiUrl -Headers $headers

    # Parse and display the file content (in this case, it's assumed to be JSON)
    $jsonContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($fileContent.content))

    # Parse the JSON content into a PowerShell object
    $jsonObject = $jsonContent | ConvertFrom-Json

    # Convert the modified JSON data back to a PowerShell object
    $encryptedJsonData = $jsonContent | ConvertFrom-Json

    # Specify the fields you want to decrypt
    $fieldsToDecrypt = $env:fieldsToDecrypt

    # Decryption key (use the same key you used for encryption)
    $keyHex = $env:key

    # Create a new AES object with the specified key and AES mode
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256  # Set the key size to 256 bits for AES-256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    # Loop through the specified fields and decrypt their values
    foreach ($field in $fieldsToDecrypt) {
        # Check if the field contains a valid Base64 string
        if ($encryptedJsonData.credentials[0].$field -ne "System.Collections.Hashtable") {
            $encryptedValueBase64 = $encryptedJsonData.credentials[0].$field.EncryptedValue
            $IVBase64 = $encryptedJsonData.credentials[0].$field.IV

            # Convert IV and encrypted value to bytes
            $IV = [System.Convert]::FromBase64String($IVBase64)
            $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

            # Create a decryptor
            $decryptor = $AES.CreateDecryptor($AES.Key, $IV)

            # Decrypt the data
            $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
            $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

            # Update the JSON object with the decrypted value
            $encryptedJsonData.credentials[0].$field = $decryptedText
        }
    }

    # Display the JSON object with decrypted values
    $decrypteddata = $encryptedJsonData | ConvertTo-Json -Depth 10

    Write-Host "Decrypted Data:"
    Write-Host $decrypteddata

#     # Define your GitHub username, repository names, branch names, and file paths
#     $githubUsername = $env:targetgithubUsername
#     $repositoryName = $env:repositoryName
#     $targetBranchName = $env:targetBranchName
#     $targetFilePath = $env:targetFilePath

#     # Define your GitHub personal access token
#     $githubToken = $git_token  # Replace with your GitHub token
    
#     # Encode the content you want to update as base64
#     $updatedContent = $decrypteddata
#     $updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedContent))
    
#     # Define the API URL to fetch the file content from the source branch
#     $apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$targetFilePath+"?ref="+$targetBranchName
    
#     # Set the request headers with your personal access token
#     $headers = @{
#         Authorization = "Bearer $githubToken"
#         "Content-Type" = "application/json"
#     }
    
#     # Check if the file already exists in the repository and fetch its current SHA
#     $fileExists = $false
#     $sha = $null
#     try {
#         $fileContent = Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = "Bearer $githubToken" }
#         $fileExists = $true
#         $sha = $fileContent.sha
#     }
#     catch {
#         # The file doesn't exist
#     }
    
#     # Create a JSON body for the API request
#     $requestBody = @{
#         "branch" = $sourceBranchName
#         "message" = "Update Decrypted Data"
#         "content" = $updatedContentBase64  # Use the base64-encoded content
#         "sha" = $sha  # Include the current SHA
#     } | ConvertTo-Json
    
#     # Determine whether to make a PUT or POST request based on whether the file exists
#     if ($fileExists) {
#         # File already exists, make a PUT request to update it
#         try {
#             Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody
    
#             Write-Host "Decrypted data has been successfully updated in $targetFilePath in branch $sourceBranchName."
#         }
#         catch {
#             Write-Host "An error occurred while updating the file: $_"
#         }
#     }
#     else {
#         # File doesn't exist, make a POST request to create it
#         try {
#             Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody
    
#             Write-Host "Decrypted data has been successfully created in $targetFilePath in branch $sourceBranchName."
#         }
#         catch {
#             Write-Host "An error occurred while creating the file: $_"
#         }
#     }
# }
# catch {
#     Write-Host "An error occurred: $_"
# }
