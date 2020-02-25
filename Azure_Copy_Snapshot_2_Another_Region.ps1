Clear-Host

$day = Get-Date -f ddMMMyy
$sourceSubscriptionId = (Get-AzSubscription | Select-Object Name,Id | Out-GridView -Title "Select Azure Subscription" -OutputMode Single).Id
$sourceRG = Get-AzResourceGroup (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Source Resource Group" -OutputMode Single).ResourceGroupName
$sourceResourceGroupName = $sourceRG.ResourceGroupName
$destRG = Get-AzResourceGroup (Get-AzResourceGroup | Select-Object ResourceGroupName, Location | Out-GridView -Title "Select a Destination Resource Group"-OutputMode Single).ResourceGroupName
$disks = (Get-AzDisk -ResourceGroupName $sourceResourceGroupName | Select-Object Name | Out-GridView -Title "Select Disks to Snapshot" -OutputMode multiple).Name
$region = $destRG.Location
$resourceGroupName = $destRG.ResourceGroupName
$storageAccountName = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName | Select-Object StorageAccountName | Out-GridView -Title "Select a Storage Account to store snpashots" -OutputMode Single).StorageAccountName

# Set up the target storage account in the other region
$imageContainerName = "snapshots"
$targetStorageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
try{New-AzureStorageContainer -Name $imageContainerName -Context $targetStorageContext -Permission Container -ErrorAction Stop}catch{Write-Warning $_}


foreach($disk in $disks){
    $id = (Get-AzDisk -ResourceGroupName $sourceResourceGroupName -Name $Disk).Id
    $imageBlobName = (($disk).Split('_'))[0] + "-"+ (($disk).Split('_'))[1]

    # Create the name of the snapshot, using the current region in the name.
    $snapshotName = $imageBlobName + "-" + $region
    $snapshot =  New-AzSnapshotConfig -SourceUri $id -CreateOption Copy -Location $sourceRG.Location
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $sourceResourceGroupName

    # Get the source snapshot
    $snap = Get-AzSnapshot -ResourceGroupName $sourceResourceGroupName  -SnapshotName $snapshotName

    # Create a Shared Access Signature (SAS) for the source snapshot
    $snapSasUrl = (Grant-AzSnapshotAccess -ResourceGroupName $sourceResourceGroupName -SnapshotName $snapshotName -DurationInSecond 3600 -Access Read).AccessSAS

    # Use the SAS URL to copy the blob to the target storage account (and thus region)
    Start-AzureStorageBlobCopy -AbsoluteUri $snapSasUrl -DestContainer $imageContainerName -DestContext $targetStorageContext -DestBlob $imageBlobName -Force
    Get-AzureStorageBlobCopyState -Container $imageContainerName -Blob $imageBlobName -Context $targetStorageContext -WaitForComplete

    # Get the full URI to the blob
    $osDiskVhdUri = ($targetStorageContext.BlobEndPoint + $imageContainerName + "/" + $imageBlobName)

    # Build up the snapshot configuration, using the target storage account's resource ID
    $snapshotConfig = New-AzSnapshotConfig -AccountType Premium_LRS `
                                                -OsType Linux `
                                                -Location $region `
                                                -CreateOption Import `
                                                -SourceUri $osDiskVhdUri `
                                                -StorageAccountId "/subscriptions/${sourceSubscriptionId}/resourceGroups/${resourceGroupName}/providers/Microsoft.Storage/storageAccounts/${storageAccountName}"

    # Create the new snapshot in the target region
    $snapshotName = $imageBlobName + "-" + $region
    $snap2 = New-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig
}
