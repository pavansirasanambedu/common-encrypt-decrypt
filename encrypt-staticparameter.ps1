# Define the encryption key
$keyHex = $env:key  # Replace with your encryption key

# Define the git token
# $gittoken = $env:github_token  # Replace with your git token

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Specify the plain text to be encrypted
$plainText = $env:value

Write-Host "plainText: $plainText"

# Convert plaintext to bytes (UTF-8 encoding)
$plainTextBytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)

# Generate a random initialization vector (IV)
$AES.GenerateIV()
$IVBase64 = [System.Convert]::ToBase64String($AES.IV)

# Encrypt the data
$encryptor = $AES.CreateEncryptor()
$encryptedBytes = $encryptor.TransformFinalBlock($plainTextBytes, 0, $plainTextBytes.Length)
$encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

# Display the encrypted data
Write-Host "Encrypted Text: $encryptedBase64"

# Define the local file path and file name
$filePath = "encrypt/encrypt-plaintext.json"

# Write the JSON data to the file
$encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8
