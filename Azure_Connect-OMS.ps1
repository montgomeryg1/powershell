Clear-Host

$workspace = (Get-AzOperationalInsightsWorkspace | Select-Object Name,ResourceGroupName,CustomerId | Out-GridView -Title "Select Source Subscription" -OutputMode Single)
$workspaceName = $workspace.Name
$workspaceResourceGroup = $workspace.ResourceGroupName
$workspaceId = $workspace.CustomerId
$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $workspace.ResourceGroupName -Name $workspace.Name).PrimarySharedKey

$vmNames = @()
$resourcegroups =  (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group/s" -OutputMode Multiple).ResourceGroupName


foreach($resourcegroup in $resourcegroups){
    $results = @()
    $vmNames = (Get-AzVM -ResourceGroupName $resourcegroup | Select-Object Name,ResourceGroupName | Out-GridView -Title "Select Virtual Machines" -OutputMode Multiple).Name

    $Activity = "Creating Log Analytics connections"
    $Id = 1
    $Step = 1
    $TotalSteps = $vmNames.count

    if($vmNames){
        foreach ($vmName in $vmNames)
        {
            $vm = Get-AzVm -ResourceGroupName $resourcegroup -Name $vmName
            $location = $vm.Location
            $name = $vm.Name
            $extensions = $vm.Extensions

            $StepText   = "Removing Agent on: " + $vm.Name + " in resource group " + $vm.ResourceGroupName
            $StatusText = '"VM $($Step.ToString().PadLeft($TotalSteps.Count.ToString().Length)) of $TotalSteps | $StepText"'
            $StatusBlock = [ScriptBlock]::Create($StatusText)
            Write-Progress -Activity $Activity -Status (&$StatusBlock) -PercentComplete ($Step / $TotalSteps * 100)

            foreach ($extension in  $extensions)
            {
                $extension.VirtualMachineExtensionType
                if (($extension.VirtualMachineExtensionType -like "*OmsAgentForLinux*" ) `
                -or ($extension.VirtualMachineExtensionType -like "*LinuxDiagnostic*") `
                -or ($extension.VirtualMachineExtensionType -like "*MicrosoftMonitoringAgent*"))
                {
                    $results += Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                                                          -Name $extension.VirtualMachineExtensionType `
                                                          -VMName $name -force
                }
            }

            try{
                if(($vm.OSProfile).WindowsConfiguration){
                    $result = Set-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                        -VMName $name `
                        -Name 'MicrosoftMonitoringAgent' `
                        -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
                        -ExtensionType 'MicrosoftMonitoringAgent' `
                        -TypeHandlerVersion '1.0' `
                        -Location $location `
                        -SettingString "{'workspaceId': '$workspaceId'}" -ProtectedSettingString "{'workspaceKey': '$workspaceKey'}"
               }
                if(($vm.OSProfile).LinuxConfiguration) {
                    $result = Set-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                        -VMName $name `
                        -Name 'OmsAgentForLinux' `
                        -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
                        -ExtensionType 'OmsAgentForLinux' `
                        -TypeHandlerVersion '1.0' `
                        -Location $location `
                        -SettingString "{'workspaceId': '$workspaceId'}" -ProtectedSettingString "{'workspaceKey': '$workspaceKey'}"
                }
            }catch{
                Write-Warning $_
            }
            $Step++
        }
    }
    $results
}
