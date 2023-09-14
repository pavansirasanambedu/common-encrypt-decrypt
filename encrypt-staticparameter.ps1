try {
    $git_token = $env:token

    # Plain text to encrypt
    $plainText = $env:staticvalue

    # Encryption key
    $keyHex = $env:key

    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    # Convert plain text to bytes (UTF-8 encoding)
    $plainTextBytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)

    $AES.GenerateIV()
    $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

    # Encrypt the data
    $encryptor = $AES.CreateEncryptor()
    $encryptedBytes = $encryptor.TransformFinalBlock($plainTextBytes, 0, $plainTextBytes.Length)
    $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

    # Define your GitHub username, repository names, branch names, and file paths
    $githubUsername = $env:targetgithubUsername
    $repositoryName = $env:targetrepositoryName
    $sourceBranchName = $env:targetBranchName
    $targetFilePath = $env:targetFilePath

    # Define your GitHub personal access token
    $githubToken = $git_token  # Replace with your GitHub token

    # Encode the content you want to update as base64
    $updatedContent = @{
        "EncryptedValue" = $encryptedBase64
        "IV" = $IVBase64
    } | ConvertTo-Json

    $updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedContent))

    # Define the API URL to fetch the file content from the source branch
    $apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$targetFilePath+"?ref="+$sourceBranchName

    # Set the request headers with your personal access token
    $headers = @{
        Authorization = "Bearer $githubToken"
        "Content-Type" = "application/json"
    }

    # Check if the file already exists in the repository and fetch its current SHA
    $fileExists = $false
    $sha = $null
    try {
        $fileContent = Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = "Bearer $githubToken" }
        $fileExists = $true
        $sha = $fileContent.sha
    }
    catch {
        # The file doesn't exist
    }

    # Create a JSON body for the API request
    $requestBody = @{
        "branch" = $sourceBranchName
        "message" = "Update Encrypted Data"
        "content" = $updatedContentBase64  # Use the base64-encoded content
        "sha" = $sha  # Include the current SHA
    } | ConvertTo-Json

    # Determine whether to make a PUT or POST request based on whether the file exists
    if ($fileExists) {
        # File already exists, make a PUT request to update it
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "Encrypted data has been successfully updated in $targetFilePath in branch $sourceBranchName."
        }
        catch {
            Write-Host "An error occurred while updating the file: $_"
        }
    }
    else {
        # File doesn't exist, make a POST request to create it
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "Encrypted data has been successfully created in $targetFilePath in branch $sourceBranchName."
        }
        catch {
            Write-Host "An error occurred while creating the file: $_"
        }
    }
}
catch {
    Write-Host "An error occurred: $_"
}
