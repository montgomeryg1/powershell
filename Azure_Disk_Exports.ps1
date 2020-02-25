#Provide the subscription Id of the subscription where managed disk is created
$subscriptionId = (Get-AzSubscription | Select-Object Name, Id | Out-GridView -Title "Select Azure Subscription" -OutputMode Single).Id

# Set the context to the subscription Id where managed disk is created
Select-AzSubscription -SubscriptionId $SubscriptionId

#Provide the name of your resource group where managed is created
$resourceGroupNames = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Source Resource Group" -OutputMode multiple).ResourceGroupName


#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/Az.Storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "3600"

#Provide storage account name where you want to copy the underlying VHD of the managed disk. 
$storageAccountResourceGroup = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Storage Account Resource Group" -OutputMode single).ResourceGroupName
$storageAccount = Get-AzStorageAccount -ResourceGroupName $storageAccountResourceGroup | Out-GridView -Title "Select Storage Account" -OutputMode single
$ctx = $storageAccount.Context

#Provide the key of the storage account where you want to copy the VHD of the managed disk. 
$storageAccountKey = (($storageAccount.Context).ConnectionString -split 'AccountKey=')[1]

$destinationURL = "https://*****.blob.core.windows.net/"

foreach ($resourceGroupName in $resourceGroupNames) {

    #Name of the storage container where the downloaded VHD will be stored
    try {
        $storageContainerName = (Get-AzStorageContainer -Name ${resourceGroupName}vhdbackups -context $ctx -ErrorAction Stop).Name
    }
    catch {
        $storageContainerName = (New-AzStorageContainer -Name ${resourceGroupName}vhdbackups -context $ctx -Permission Off).Name
    }
    
    $destinationURLContainer = $destinationURL + $storageContainerName

    #Provide the managed disk name 
    $diskNames = (Get-AzDisk -ResourceGroupName $resourceGroupName | Select-Object Name | Out-GridView -Title "Select Disks to Snapshot" -OutputMode multiple).Name

    if ($diskNames) {

        foreach ($diskName in $diskNames) {
        
            #Generate the SAS for the managed disk 
            $sas = Grant-AzDiskAccess -ResourceGroupName $resourceGroupName -DiskName $diskName -DurationInSecond $sasExpiryDuration -Access Read 

            #Create the context of the storage account where the underlying VHD of the managed disk will be copied
            $destinationContext = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageAccountKey

            $containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($sasExpiryDuration) -Name $storageContainerName -Permission rwd
            $destinationVHDFileName = $destinationURLContainer + "/" + $diskName + ".vhd" + $containerSASURI
            Write-Host $destinationVHDFileName

            & azcopy copy $sas.AccessSAS $destinationVHDFileName #| Out-Null
        }#foreach($diskName in $diskNames)

    }#if($diskNames)

}