# Define a function to encrypt fields
function Encrypt-Fields {
    param (
        [System.Object]$data,
        [System.String[]]$fieldsToEncrypt,
        [System.Security.Cryptography.AesCryptoServiceProvider]$AES
    )

    foreach ($field in $fieldsToEncrypt) {
        $dataValue = $data.$field

        $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($dataValue)

        $AES.GenerateIV()
        $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

        $encryptor = $AES.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
        $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

        $data.$field = @{
            "EncryptedValue" = $encryptedBase64
            "IV" = $IVBase64
        }
    }

    return $data
}

try {
    $git_token = $env:token

    $env:JSON_FILE_PATH = "kvmdata/kvmdata.json"

    # Load JSON content from the file
    $jsonContent = Get-Content $env:JSON_FILE_PATH -Raw | ConvertFrom-Json
    Write-Host "jsonContent: $jsonContent"

    # Decryption key
    $keyHex = $env:key

    # Specify the fields you want to encrypt
    $fieldsToEncrypt = $env:fieldsToEncrypt -split ","
    Write-Host "fieldsToEncrypt: $fieldsToEncrypt"

    # Define the path to the fields in your JSON data
    $fieldPath = $env:FIRST_LEVEL_OBJECT

    # Create an AES object for encryption
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    # Loop through the JSON data and encrypt specified fields
    foreach ($entry in $jsonContent.$fieldPath) {
        Write-Host "Entered into FOREACH...!"
        # Call the Encrypt-Fields function to encrypt the specified fields
        $entry = Encrypt-Fields -data $entry -fieldsToEncrypt $fieldsToEncrypt -AES $AES
    }

    # Convert the JSON data back to a string
    $encryptedJsonData = $jsonContent | ConvertTo-Json -Depth 10

    Write-Host "Encrypted data: $encryptedJsonData"

}
catch {
    Write-Host "An error occurred: $_"
}























# try {
#     $git_token = $env:token
    
#     $jsonContent = $env:jsondata
#     Write-Host "Initial fileContent: $jsonContent"

#     $inputjsonpayload = $jsonContent | ConvertFrom-Json
#     Write-Host $inputjsonpayload

#     # Encryption key
#     $keyHex = $env:key

#     # Specify the fields you want to decrypt
#     $fieldsToEncrypt = $env:fieldsToEncrypt -split ","

#     $firstobjectname = $env:firstobject
#     Write-Host $firstobjectname

#     $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
#     $AES.KeySize = 256
#     $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
#     $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

#     foreach ($entry in $inputjsonpayload.$firstobjectname) {
#         # Write-Host "Processing entry: $($entry.name)"

#         foreach ($field in $fieldsToEncrypt) {
#             $data = $entry.$field

#             $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($data)

#             $AES.GenerateIV()
#             $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

#             $encryptor = $AES.CreateEncryptor()
#             $encryptedBytes = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)
#             $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

#             $entry.$field = @{
#                 "EncryptedValue" = $encryptedBase64
#                 "IV" = $IVBase64
#             }
#         }
#     }

#     $encryptedJsonData = $inputjsonpayload | ConvertTo-Json -Depth 10

#     Write-Host "Encrypted data: $encryptedJsonData"

#     # Define your GitHub username, repository names, branch names, and file paths
#     $githubUsername =  $env:targetgithubUsername
#     $repositoryName = $env:targetrepositoryName
#     $targetBranchName = $env:targetBranchName
#     $targetFilePath = $env:targetFilePath
    
#     # Define your GitHub personal access token
#     $githubToken = $git_token  # Replace with your GitHub token
    
#     # Encode the content you want to update as base64
#     $updatedContent = $encryptedJsonData
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
#         "branch" = $targetBranchName  # Corrected variable name
#         "message" = "Update Decrypted Data"
#         "content" = $updatedContentBase64  # Use the base64-encoded content
#         "sha" = $sha  # Include the current SHA
#     } | ConvertTo-Json
    
#     # Determine whether to make a PUT or POST request based on whether the file exists
#     if ($fileExists) {
#         # File already exists, make a PUT request to update it
#         try {
#             Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody
    
#             Write-Host "Encrypted data has been successfully updated in $targetFilePath in branch $targetBranchName."
#         }
#         catch {
#             Write-Host "An error occurred while updating the file: $_"
#         }
#     }
#     else {
#         # File doesn't exist, make a POST request to create it
#         try {
#             Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody
    
#             Write-Host "Decrypted data has been successfully created in $targetFilePath in branch $targetBranchName."
#         }
#         catch {
#             Write-Host "An error occurred while creating the file: $_"
#         }
#     }



# }
# catch {
#     Write-Host "An error occurred: $_"
# }
