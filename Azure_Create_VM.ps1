$myLocation = 'uksouth'
$myResourceGroup = 'myResourceGroup'

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $myResourceGroup -Location $myLocation `
    -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $myResourceGroup -Location $myLocation `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"

# Create a public IP address and specify a DNS name
$lbpip = New-AzPublicIpAddress -ResourceGroupName $myResourceGroup -Location $myLocation `
    -AllocationMethod Dynamic -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWWW  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80 -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $myResourceGroup -Location $myLocation `
    -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP,$nsgRuleWeb

# Create AvailabilitySet
$avset = New-AzAvailabilitySet -ResourceGroupName $$myResourceGroup -Location $myLocation | foreach{$_.Id}

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $myResourceGroup -Location $myLocation `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$cred = Get-Credential

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig -VMName myVM -VMSize Standard_DS2 -AvailabilitySetId $avset | `
    Set-AzVMOperatingSystem -Windows -ComputerName myVM -Credential $cred | `
    Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nic.Id

$frontendIP = New-AzLoadBalancerFrontendIpConfig `
                    -Name LB-frontend `
                    -PrivateIpAddress $lbpip `
                    -SubnetId ($vnet.Subnets | Where-Object {$_.Name -match 'net-test'}).Id

$beaddresspool= New-AzLoadBalancerBackendAddressPoolConfig -Name 'LB-backend'

$healthProbe = New-AzLoadBalancerProbeConfig `
                    -Name "lbprobe" `
                    -Protocol tcp -Port 3389 `
                    -IntervalInSeconds 5 `
                    -ProbeCount 2

$lbrule = New-AzLoadBalancerRuleConfig `
                    -Name "lbrule" `
                    -FrontendIpConfiguration $frontendIP `
                    -BackendAddressPool $beAddressPool `
                    -Probe $healthProbe `
                    -Protocol Tcp `
                    -FrontendPort 443 `
                    -BackendPort 3389

$lb = New-AzLoadBalancer `
                    -ResourceGroupName $rgName `
                    -Name $myLBName `
                    -Location $mylocation `
                    -FrontendIpConfiguration $frontendIP `
                    -LoadBalancingRule $lbrule `
                    -BackendAddressPool $beAddressPool `
                    -Probe $healthProbe

$lb= get-Azloadbalancer -name $myLBName -resourcegroupname $myResourceGroup
$backend=Get-AzLoadBalancerBackendAddressPoolConfig -name LB-backend -LoadBalancer $lb
$nic =get-Aznetworkinterface -name myNic -resourcegroupname $myResourceGroup
$nic.IpConfigurations[0].LoadBalancerBackendAddressPools=$backend
Set-AzNetworkInterface -NetworkInterface $nic