try {
    $git_token = $env:token
    
    $jsonContent = $env:jsondata
    Write-Host "Initial fileContent: $jsonContent"

    $inputjsonpayload = $jsonContent | ConvertFrom-Json
    Write-Host $inputjsonpayload

    # Encryption key
    $keyHex = $env:key

    # Specify the fields you want to decrypt
    $fieldsToEncrypt = $env:fieldsToEncrypt -split ","

    $firstobjectname = $env:firstobject
    Write-Host $firstobjectname

    $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $AES.KeySize = 256
    $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

    foreach ($entry in $inputjsonpayload.$firstobjectname) {
        # Write-Host "Processing entry: $($entry.name)"

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

    $encryptedJsonData = $inputjsonpayload | ConvertTo-Json -Depth 10

    Write-Host "Encrypted data: $encryptedJsonData"

    # Rest of your GitHub update code...

}
catch {
    Write-Host "An error occurred: $_"
}
