$token = $env:TOKEN
$headers = @{Authorization = "Bearer $token"}

# Make the API call to get the data
$appdetailget = Invoke-RestMethod -Uri "https://apigee.googleapis.com/v1/organizations/esi-apigee-x-394004/developers/test.developer@gmail.com/apps/developer-test-app" -Method 'GET' -Headers $headers

# Specify the fields you want to encrypt
$fieldsToEncrypt = $env:fieldsToEncrypt -split ","

# Encryption key
$keyHex = $env:key  # Replace with your encryption key

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Loop through the specified fields and encrypt their values
foreach ($field in $fieldsToEncrypt) {

    # Check if the credentials array exists and has at least one item
    if ($appdetailget.credentials.Count -gt 0) {

        # Access the value of the current field
        $plaintext = $appdetailget.credentials[0].$field

        # Convert plaintext to bytes (UTF-8 encoding)
        $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

        # Generate a random initialization vector (IV)
        $AES.GenerateIV()
        $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

        # Encrypt the data
        $encryptor = $AES.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)
        $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

        # Store the encrypted value back in the JSON data
        $appdetailget.credentials[0].$field = @{
            "EncryptedValue" = $encryptedBase64
            "IV" = $IVBase64
        }
    }
}

# Convert the modified JSON data back to JSON format with a higher depth value
$encryptedJsonData = $appdetailget | ConvertTo-Json -Depth 10

# Display the modified JSON data
Write-Host $encryptedJsonData

# Define the local file path and file name
$filePath = $env:sourcepath

# Write the JSON data to the file
$encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8

# Define your GitHub username, repository names, branch names, and file paths
$githubUsername = "pavansirasanambedu"
$repositoryName = "common-encrypt-decrypt"
$targetBranchName = "decrypt/jsonpayload"
$targetFilePath = "decrypt-jsonpaload/decrypt-jsonpaload.json"

# Define your GitHub personal access token
$githubToken = $git_token  # Replace with your GitHub token

# Encode the content you want to update as base64
$updatedContent = $decrypteddata
$updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedContent))

# Define the API URL to fetch the file content from the source branch
$apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$targetFilePath+"?ref="+$targetBranchName

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
    "branch" = $targetBranchName  # Corrected variable name
    "message" = "Update Decrypted Data"
    "content" = $updatedContentBase64  # Use the base64-encoded content
    "sha" = $sha  # Include the current SHA
} | ConvertTo-Json

# Determine whether to make a PUT or POST request based on whether the file exists
if ($fileExists) {
    # File already exists, make a PUT request to update it
    try {
        Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

        Write-Host "Decrypted data has been successfully updated in $targetFilePath in branch $targetBranchName."
    }
    catch {
        Write-Host "An error occurred while updating the file: $_"
    }
}
else {
    # File doesn't exist, make a POST request to create it
    try {
        Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

        Write-Host "Decrypted data has been successfully created in $targetFilePath in branch $targetBranchName."
    }
    catch {
        Write-Host "An error occurred while creating the file: $_"
    }
}
