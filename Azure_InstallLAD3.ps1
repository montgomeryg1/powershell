Function InstallLAD3{
    param(
            # RG name of the VM
            [string]$RGName = 'myResourceGroup'
    )

    # Location of the resources
    $Location = 'northeurope'

    # Extension Name
    $ExtensionName = 'LinuxDiagnostic'

    # Publisher Name
    $Publisher = 'Microsoft.Azure.Diagnostics'

    # LAD version
    $Version = '3.0'

    $diagStore = 'storediagnostic'
    $sasToken = '****'
    
    $linuxMachines = @()

    $linuxNames = (Get-AzVM -ResourceGroupName $RGName | Select-Object Name | Out-GridView -Title "Select VM" -OutputMode Multiple).Name
    
    foreach($linuxName in $linuxNames){
        $linuxMachines += Get-AzVM -ResourceGroupName $RGName -Name $linuxName | ForEach-Object {[PSCustomObject]@{'Name'=$_.Name;'Id'=$_.Id}}
    }
    foreach($linuxMachine in $linuxMachines){

        $PublicConf = Get-Content C:\Scripts\PublicConfig.json -Raw | ForEach-Object {$_ -replace '__VM_RESOURCE_ID__',$linuxMachine.Id}
        $PublicConf = $PublicConf | ForEach-Object {$_ -replace 'STORAGE_NAME',$diagStore}
        $PrivateConf = Get-Content C:\Scripts\PrivateConfig.json -Raw | ForEach-Object {$_ -replace 'STORAGE_NAME',$diagStore}
        $PrivateConf = $PrivateConf | ForEach-Object {$_ -replace 'SAS_TOKEN',$sasToken}

        # Install and configure the extension
        try
        {
            Write-Host 'Installing extension on' $linuxMachine.Name -ForegroundColor Green
            Set-AzVMExtension -ResourceGroupName $RGName -VMName $linuxMachine.Name -Location $Location `
                -Name $ExtensionName -Publisher $Publisher `
                -ExtensionType $ExtensionName -TypeHandlerVersion $Version `
                -Settingstring $PublicConf -ProtectedSettingString $PrivateConf `
                -ErrorAction Stop | Out-Null
            Write-Host 'Successfully installed extension on' $linuxMachine.Name -ForegroundColor Green
            Write-Host ""
        }
        catch
        {
            Write-Host $_ -ForegroundColor Yellow
            Write-Host 'Failed to install extension on' $linuxMachine.Name -ForegroundColor Yellow
            Write-Host ""
        }

    }
}

