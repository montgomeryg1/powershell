Stop-AzVM -ResourceGroup "myResourceGroup" `
    -Name "myVM"

$nic = Get-AzNetworkInterface -ResourceGroupName "myResourceGroup" `
    -Name "myNic"

$nic.EnableAcceleratedNetworking = $false
$nic | Set-AzNetworkInterface