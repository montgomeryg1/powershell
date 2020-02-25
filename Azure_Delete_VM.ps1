function Delete-VM {

    Param(
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'Parameter Set 1')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[a-z]*")]
        [Alias("ResourceGroup")]
        $rGrp,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            ParameterSetName = 'Parameter Set 1')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[a-z]*")]
        [Alias("Name")]
        $vmName
    )
    Clear-Host


    $vm = Get-AzVm -Name $vmName -ResourceGroupName $rGrp

    #$networkCards = $vm.NetworkProfile.NetworkInterfaces
    $osDisk = $vm.StorageProfile.OsDisk.Name
    $dataDisks = $vm.StorageProfile.DataDisks | ForEach-Object { $_.Name }

    $vm | Remove-AzVM -Force
    Remove-AzDisk -ResourceGroupName $rGrp -DiskName $osDisk -force

    if ($dataDisks.Count -gt 0) {
        $i = 1
        foreach ($dataDisk in $dataDisks) {
            Write-Progress -Activity "Removing data disks" -status "Deleting resource $dataDisk : Disk $i of $($dataDisks.Count)" -percentComplete ($i / $dataDisks.Count*100)
            Remove-AzDisk -ResourceGroupName $rGrp -DiskName $dataDisk -force
            $i++
        }
    }

    <#
    if($networkCards.Count -gt 0){
        $i=1
        foreach($networkCard in $networkCards){
            Write-Progress -Activity "Removing network cards" -status "Deleting resource $networkCard : NIC $i of $($networkCards.Count)" -percentComplete ($i / $networkCards.count*100)
            $net = (Get-AzNetworkInterface -ResourceGroupName $rGrp | Where {$_.Id -eq $networkCard.Id}).Name
            Remove-AzNetworkInterface -Name $net -ResourceGroupName $rGrp -force
        }
    }
    #>


}

$rg = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group" -OutputMode Single).ResourceGroupName
$names = (Get-AzVm -ResourceGroupName $rg | Select-Object Name | Out-GridView -Title "Select a VM" -OutputMode Multiple).Name
foreach ($name in $names) {
    Delete-VM -rGrp $rg -vmName $name
}
