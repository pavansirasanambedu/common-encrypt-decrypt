try {
    $git_token = $env:token

    $jsonContent = $env:jsondata
    
    Write-Host "Initial fileContent: $jsonContent"

    $inputjsonpayload = $jsonContent | ConvertFrom-Json

    # Encryption key
    $keyHex = $env:key

    $firstobjectname = $env:firstobject
    Write-Host $firstobjectname

    # Specify the fields you want to decrypt
    $fieldsToEncrypt = @($env:fieldsToEncrypt)

    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    foreach ($entry in $inputjsonpayload.$firstobjectname) {
        Write-Host "Processing entry: $($entry.name)"
        Write-Host $inputjsonpayload.$firstobjectname
        Write-Host "fieldname: $fieldsToEncrypt"

        foreach ($field in $fieldsToEncrypt) {
            $data = $entry.$field

            $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)

            $AES.GenerateIV()
            $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

            $encryptor = $AES.CreateEncryptor()
            $encryptedBytes = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
            $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

            $entry.$field = @{
                "EncryptedValue" = $encryptedBase64
                "IV" = $IVBase64
            }
        }
    }

    $encryptedJsonData = $appdetailget | ConvertTo-Json -Depth 10

    Write-Host "Encrypted data: $encryptedJsonData"

    # Define your GitHub username, repository names, branch names, and file paths
    $githubUsername = $env:targetgithubUsername
    $repositoryName = $env:targetrepositoryName
    $sourceBranchName = $env:targetBranchName
    $targetFilePath = $env:targetFilePath

    # Define your GitHub personal access token
    $githubToken = $git_token  # Replace with your GitHub token

    # Encode the content you want to update as base64
    $updatedContent = $encryptedJsonData
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
        "message" = "Update Decrypted Data"
        "content" = $updatedContentBase64  # Use the base64-encoded content
        "sha" = $sha  # Include the current SHA
    } | ConvertTo-Json

    # Determine whether to make a PUT or POST request based on whether the file exists
    if ($fileExists) {
        # File already exists, make a PUT request to update it
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "encrypted data has been successfully updated in $targetFilePath in branch $sourceBranchName."
        }
        catch {
            Write-Host "An error occurred while updating the file: $_"
        }
    }
    else {
        # File doesn't exist, make a POST request to create it
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "Decrypted data has been successfully created in $targetFilePath in branch $sourceBranchName."
        }
        catch {
            Write-Host "An error occurred while creating the file: $_"
        }
    }
}
catch {
    Write-Host "An error occurred: $_"
}
