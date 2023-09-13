$git_token = $env:token

# Define your GitHub username, repository names, branch name, and file path
$githubUsername = "pavansirasanambedu"
$sourceRepo = "common-encrypt-decrypt"
$branchName = "encrypt/appkeys"
$filePath = "encrypt/encrypt-appkeys.json"

# Define the GitHub API URL for fetching the file content from a specific branch
$apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$sourceRepo+"/contents/"+$filePath+"?ref="+$branchName

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
    $fieldsToDecrypt = @("consumerKey", "consumerSecret")

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

    # Define your GitHub username, repository names, branch names, and file paths
    $githubUsername = "pavansirasanambedu"
    $repositoryName = "common-encrypt-decrypt"
    $sourceBranchName = "decrypt/appkeys"  # Source branch where you want to update the file
    $targetFilePath = "decrypt/decrypt-appkeys.json"  # File path in the source branch

    # Encode the content you want to update as base64
    $updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$decrypteddata"))

    # Define the API URL to fetch the file content from the source branch
    $apiUrl = "https://api.github.com/repos/$githubUsername/$repositoryName/contents/$targetFilePath?ref=$sourceBranchName"

    try {
        # Check if the file already exists in the repository and fetch its current SHA
        $fileExists = $false
        $sha = $null
        $fileContent = Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = "Bearer $git_token" }
        $fileExists = $true
        $sha = $fileContent.sha

        # Create a JSON body for the API request
        $requestBody = @{
            "branch" = $sourceBranchName
            "message" = "Update Decrypted Data"
            "content" = $updatedContentBase64  # Use the base64-encoded content
            "sha" = $sha  # Include the current SHA
        } | ConvertTo-Json

        # File already exists, make a PUT request to update it
        Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

        Write-Host "Decrypted data has been successfully updated in $targetFilePath in branch $sourceBranchName."
    }
    catch {
        # File doesn't exist, make a POST request to create it
        $requestBody = @{
            "branch" = $sourceBranchName
            "message" = "Create Decrypted Data"
            "content" = $updatedContentBase64  # Use the base64-encoded content
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method POST -Body $requestBody

        Write-Host "Decrypted data has been successfully written to $targetFilePath in branch $sourceBranchName."
    }
}
catch {
    Write-Host "An error occurred: $_"
}
