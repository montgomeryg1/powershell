
$StorageResourceGroupName = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group" -OutputMode Single).ResourceGroupName
$StorageAccount = (Get-AzStorageAccount -ResourceGroupName $StorageResourceGroupName | Out-GridView -Title "Select a Storage Account" -OutputMode Single)
$StorageContainerName = (Get-AzureStorageContainer -Context $StorageAccount.Context | Select-Object Name | Out-GridView -Title "Select a Container" -OutputMode Single).Name
$_artifactsLocation = $StorageAccount.Context.BlobEndPoint + $StorageContainerName
$_artifactsLocationSasToken = New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddMonths(1)


Write-Host ($_artifactsLocation + "/DSC/WindowsConfig.zip" +$_artifactsLocationSasToken)
