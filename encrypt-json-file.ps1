$git_token = $env:token

$githubUsername = "pavansirasanambedu"
$repositoryName = "common-encrypt-decrypt"
$branchName = "encrypt/jsonfile"
$filePath = "encrypt-jsonfile/encrypt.json"

$apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$filePath+"?ref="+$branchName

$headers = @{
    Authorization = "Bearer $git_token"
}

try {
    $fileContent = Invoke-RestMethod $apiUrl -Headers $headers

    $jsonContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($fileContent.content))
    $appdetailget = $jsonContent | ConvertFrom-Json

    # Specify the fields you want to encrypt
    $fieldsToEncrypt = @("consumerKey", "consumerSecret")

    # Encryption key
    $keyHex = $env:key  # Replace with your encryption key

    # Create a new AES object with the specified key and AES mode
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256  # Set the key size to 256 bits for AES-256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    # Loop through the specified fields and encrypt their values
    foreach ($field in $fieldsToEncrypt) {
        if ($appdetailget.credentials.Count -gt 0) {
            $plaintext = $appdetailget.credentials[0].$field

            $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

            $AES.GenerateIV()
            $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

            $encryptor = $AES.CreateEncryptor()
            $encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)
            $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

            $appdetailget.credentials[0].$field = @{
                "EncryptedValue" = $encryptedBase64
                "IV" = $IVBase64
            }
        }
    }

    $encryptedJsonData = $appdetailget | ConvertTo-Json -Depth 10

    Write-Host "Encrypted Data:"
    Write-Host $encryptedJsonData

    $githubToken = $git_token

    $updatedContent = $encryptedJsonData
    $updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedContent))

    $apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$filePath+"?ref="+$branchName

    $headers = @{
        Authorization = "Bearer $githubToken"
        "Content-Type" = "application/json"
    }

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

    $requestBody = @{
        "branch" = $branchName
        "message" = "Update Encrypted Data"
        "content" = $updatedContentBase64
    } | ConvertTo-Json

    if ($fileExists) {
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "Encrypted data has been successfully updated in $filePath in branch $branchName."
        }
        catch {
            Write-Host "An error occurred while updating the file: $_"
        }
    }
    else {
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method POST -Body $requestBody

            Write-Host "Encrypted data has been successfully created in $filePath in branch $branchName."
        }
        catch {
            Write-Host "An error occurred while creating the file: $_"
        }
    }
}
catch {
    Write-Host "An error occurred: $_"
}
