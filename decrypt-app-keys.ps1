# Define the decryption key
$keyHex = $env:key  # Replace with your decryption key

$gittoken = $env:token

# Define your GitHub username, repository name, branch name, and file path in the different branch
$githubUsername = "pavansirasanambedu"
$repositoryName = "common-encrypt-decrypt"
$branchName = "encrypt/appkeys"  # The name of the branch where the file is located
$filePath = "encrypt/encrypt-appkeys.json"  # Replace with the actual file path in the branch


# # Read the encrypted JSON data from a file
# $filePath = "path/to/your/encrypted_data.json"
$encryptedJsonData = Get-Content -Path $filePath | ConvertFrom-Json

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Specify the fields you want to decrypt
$fieldsToDecrypt = @("consumerKey", "consumerSecret")

# Loop through the specified fields and decrypt their values
foreach ($field in $fieldsToDecrypt) {
    if ($encryptedJsonData.credentials[0].$field -ne $null) {
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

Write-Host $decrypteddata

# Define your GitHub username, repository name, target branch name, and file path in the target branch
$githubUsername = "pavansirasanambedu"
$repositoryName = "common-encrypt-decrypt"
$targetBranchName = "decrypt/appkeys"  # The branch where you want to create/update the file
$targetFilePath = "decrypt/decrypt-appkeys.json"  # Replace with the actual file path in the target branch

# Define your GitHub personal access token
$githubToken = $gittoken

# Encode the decrypted content as base64
$base64Content = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($decrypteddata))

# Define the API URL to create/update the file in the target branch
$apiUrl = "https://api.github.com/repos/$githubUsername/$repositoryName/contents/$targetFilePath"

# Create a JSON body for the API request
$requestBody = @{
    "branch" = $targetBranchName
    "message" = "Update Decrypted Data"
    "content" = $base64Content
} | ConvertTo-Json

# Set the request headers with your personal access token
$headers = @{
    Authorization = "Bearer $githubToken"
    "Content-Type" = "application/json"
}

try {
    # Make a PUT request to create/update the file in the target branch
    Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

    Write-Host "Decrypted data has been successfully written to $targetFilePath in branch $targetBranchName."
}
catch {
    Write-Host "An error occurred: $_"
}
