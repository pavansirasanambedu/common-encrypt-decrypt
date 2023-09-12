$keyHex = $env:key

# Input string
$inputString = $keyHex

$keyLength = 32  # 32 bytes for AES-256

# Convert the string to bytes using UTF-8 encoding
$stringBytes = [System.Text.Encoding]::UTF8.GetBytes($inputString)

# Create a 32-byte key directly from the input string (no need for SHA-256)
$keyBytes = $stringBytes + @(0) * (32 - $stringBytes.Length)

# Define your plaintext data and key
$plaintext = "Hello, Pavan...!"
$key = $keyBytes  # 32 bytes key for AES-256

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = $keyBytes
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Generate a random initialization vector (IV)
$AES.GenerateIV()
$IV = $AES.IV

# Convert plaintext to bytes (UTF-8 encoding)
$plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

# Encrypt the data
$encryptor = $AES.CreateEncryptor()
$encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)

# Convert the IV and encrypted bytes to Base64 strings for storage/transmission
$IVBase64 = [System.Convert]::ToBase64String($IV)
$encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

# Display the encrypted data and IV
Write-Host "Encrypted Data (Base64): $encryptedBase64"
Write-Host "Initialization Vector (Base64): $IVBase64"

# Convert the IV and encrypted bytes from Base64
$IV = [System.Convert]::FromBase64String($IVBase64)
$encryptedBytes = [System.Convert]::FromBase64String($encryptedBase64)

# Create a decryptor
$decryptor = $AES.CreateDecryptor()
$decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)

# Convert the decrypted bytes back to plaintext
$decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

# Display the decrypted data
Write-Host "Decrypted Data: $decryptedText"
