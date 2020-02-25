$storageContainerName = Read-Host -Prompt "Enter container name"
$connStr = Read-Host -Prompt "Enter connection string"
$ctx = New-AzureStorageContext -ConnectionString $connStr


$srcPath = 'C:\workspace\Processing'
$srcFiles = Get-ChildItem -Recurse -path $srcPath | ForEach-Object { [pscustomobject] @{Name = $_.Name; FullName = $_.FullName } }

$srcFiles | ForEach-Object {S
    Set-AzureStorageBlobContent -File $_.FullName -Blob $_.Name -Container $storageContainerName -Context $ctx -Force
} 

