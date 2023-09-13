# Define the encryption key
$keyHex = $env:key  # Replace with your encryption key

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Specify the plain text to be encrypted
$plainText = "Hello Pavan...!"

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
