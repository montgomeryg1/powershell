[string]$rg

$x = Read-Host -Prompt "Have all virtual machines been powered off? [y/n]"
switch ($x) {
    'y' { Write-Host "OK to proceed!" }
    Default { Write-Host "Please deallocate virtual machines and run script again."; exit }
}

#Create snapshots of Managed Disks
Get-AzSnapshot -ResourceGroupName $rg | Where-Object { $_.TimeCreated -lt ((Get-Date).AddDays(-7)) } | Remove-AzSnapshot -Force
$location = $rg.Location
$disks = Get-AzDisk -ResourceGroupName $rg
foreach ($disk in $disks) {
    $snapshotName = (($disk.Name).Split('_'))[0] + "_" + $x
    $snapshot = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $location
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $rg
}
