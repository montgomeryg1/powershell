$vms = @()
$subscriptions = Get-AzSubscription
foreach ($subscription in $subscriptions) {
    Select-AzSubscription -Subscription $subscription
    $vms += Get-AzVM | Select-Object Name, ResourceGroupName, Location, @{Name = "OSType"; Expression = { $_.StorageProfile.OSDisk.OSType } }

}

$vms | Export-Excel -Path $env:TEMP\ABT_VMs.xlsx -AutoSize -TableName "Virtual_Machines" -TableStyle Dark1