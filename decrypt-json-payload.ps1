try {
    $git_token = $env:token

    # Load JSON content from the file
    $jsonContent = Get-Content $env:JSON_FILE_PATH -Raw | ConvertFrom-Json
    Write-Host "jsonContent: $jsonContent"

    # Decryption key
    $keyHex = $env:key

    # Specify the fields you want to decrypt
    $fieldsToDecrypt = $env:fieldsToDecrypt -split ","
    Write-Host "fieldsToDecrypt:$fieldsToDecrypt"
    
    # Define the path to the fields in your JSON data
    $fieldPath = $env:FIRST_LEVEL_OBJECT

    # Create an AES object for decryption
    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    # Loop through the JSON data and decrypt specified fields
    foreach ($entry in $jsonContent.$fieldPath) {
        foreach ($field in $fieldsToDecrypt) {
            Write-Host "Entered into FOR EACH..!"
            $encryptedField = $entry.$field
            Write-Host "encryptedField: $encryptedField"

            if ($entry.$field) {
                $encryptedValueBase64 = $firstlevelitteratename.$field.EncryptedValue
                $IVBase64 = $firstlevelitteratename.$field.IV

                if (![string]::IsNullOrEmpty($IVBase64)) {
                    # Convert IV and encrypted value to bytes
                    $IV = [System.Convert]::FromBase64String($IVBase64)
                    $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

                    # Create a decryptor with the specified IV
                    $decryptor = $AES.CreateDecryptor($AES.Key, $IV)

                    # Decrypt the data
                    $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
                    $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

                    # Update the JSON object with the decrypted value
                    $firstlevelitteratename.$field = $decryptedText
                } else {
                    Write-Host "IV is missing for $field. Skipping decryption."
                }
            }
            

            # # Check if the field is encrypted (assuming it's an object with "EncryptedValue" and "IV")
            # if ($encryptedField -is [Hashtable] -and $encryptedField.Contains("EncryptedValue") -and $encryptedField.Contains("IV")) {
            #     Write-Host "Entered into IF CONDITION..!"
            #     $encryptedValueBase64 = $encryptedField.EncryptedValue
            #     $IVBase64 = $encryptedField.IV

            #     $IV = [System.Convert]::FromBase64String($IVBase64)
            #     $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

            #     $decryptor = $AES.CreateDecryptor()
            #     $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
            #     $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

            #     # Update the field with the decrypted value
            #     $entry.$field = $decryptedText
            # }
        }
    }

    # Convert the JSON data back to a string
    $decryptedJsonData = $jsonContent | ConvertTo-Json -Depth 10

    Write-Host "Decrypted data: $decryptedJsonData"
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

#     # Decryption key
#     $keyHex = $env:key

#     # Specify the fields you want to decrypt
#     $fieldsToDecrypt = $env:fieldsToDecrypt -split ","

#     $firstobjectname = $env:firstobject
#     Write-Host $firstobjectname

#     $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
#     $AES.KeySize = 256
#     $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
#     $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

#     foreach ($entry in $inputjsonpayload.$firstobjectname) {
#         # Write-Host "Processing entry: $($entry.name)"
#         Write-Host "fieldsToDecrypt: $fieldsToDecrypt"

#         foreach ($field in $fieldsToDecrypt) {
#             $encryptedField = $entry.$field
#             Write-Host "Entered into 2nd FOREACH...!"

#             # Check if the field is encrypted
#             if ($encryptedField -is [Hashtable]) {
#                 $encryptedValueBase64 = $encryptedField.EncryptedValue
#                 $IVBase64 = $encryptedField.IV

#                 $IV = [System.Convert]::FromBase64String($IVBase64)
#                 $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

#                 $decryptor = $AES.CreateDecryptor()
#                 $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
#                 $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

#                 # Update the field with the decrypted value
#                 $entry.$field = $decryptedText
#             }
#         }
#     }

#     $decryptedJsonData = $inputjsonpayload | ConvertTo-Json -Depth 10

#     Write-Host "Decrypted data: $decryptedJsonData"

#     # Define your GitHub username, repository names, branch names, and file paths
#     $githubUsername =  $env:targetgithubUsername
#     $repositoryName = $env:targetrepositoryName
#     $targetBranchName = $env:targetBranchName
#     $targetFilePath = $env:targetFilePath
    
#     # Define your GitHub personal access token
#     $githubToken = $git_token  # Replace with your GitHub token
    
#     # Encode the content you want to update as base64
#     $updatedContent = $decryptedJsonData
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
    
#             Write-Host "Decrypted data has been successfully updated in $targetFilePath in branch $targetBranchName."
#         }
#         catch {
#             Write-Host "An error occurred while updating the file: $_"
#         }
#     }
#     else {
#         # File doesn't exist, make a POST request to create it
#         try {
#             Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method POST -Body $requestBody
    
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
