
#Provide the subscription Id
$subscriptionId = (Get-AzSubscription | Select-Object Name,Id | Out-GridView -Title "Select a Subscription" -OutputMode Single).Id

Select-AzSubscription -SubscriptionId $subscriptionId

$rgName = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Source Resource Group" -OutputMode Single).ResourceGroupName
$vmName = (Get-AzVM -ResourceGroupName $rgName | Select-Object Name | Out-GridView -Title "Select a VM to convert to Managed Disks" -OutputMode Single).Name
Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force

ConvertTo-AzVMManagedDisk -ResourceGroupName $rgName -VMName $vmName

Start-AzVM -ResourceGroupName $rgName -Name $vmName
