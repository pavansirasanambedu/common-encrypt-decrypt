# Define the encryption key
$keyHex = $env:key  # Replace with your encryption key

# Define the git token
# $gittoken = $env:github_token  # Replace with your git token

# # Create a new AES object with the specified key and AES mode
# $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
# $AES.KeySize = 256  # Set the key size to 256 bits for AES-256
# $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
# $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# # Specify the plain text to be encrypted
# $plainText = "Hey Pavan...!"

# # Convert plaintext to bytes (UTF-8 encoding)
# $plainTextBytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)

# # Generate a random initialization vector (IV)
# $AES.GenerateIV()
# $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

# # Encrypt the data
# $encryptor = $AES.CreateEncryptor()
# $encryptedBytes = $encryptor.TransformFinalBlock($plainTextBytes, 0, $plainTextBytes.Length)
# $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

# # Display the encrypted data
# Write-Host "Encrypted Text: $encryptedBase64"

# # Define the local file path and file name
# $filePath = "encrypt/encrypt-plaintext.txt"

# # Write the JSON data to the file
# $encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8

$plaintext = "Hey Pavan...!"

# Specify the fields you want to encrypt
$fieldsToEncrypt = @("plaintext")

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
$filePath = "encrypt/encrypt-plaintext.json"

# Write the JSON data to the file
$encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8
