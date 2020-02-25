

$rgName = Read-Host -Prompt "Enter resource group name"
$vmName = Read-Host -Prompt "Enter virtual machine name"
$computerName = Read-Host -Prompt "Enter computer name"
$nicName = Read-Host -Prompt "Enter network interface name"
$vmSize = "Standard_DS2_v2"
$location = Read-Host -Prompt "Enter location"
$imageName = Read-Host -Prompt "Enter image name"
$urlOfUploadedImageVhd = "https://zzzzzzzzz.blob.core.windows.net/vhd/MY-NEW-VM.vhd"


$osDiskName = 'myOsDisk'

$osDisk = New-AzDisk -DiskName $osDiskName -Disk `
    (New-AzDiskConfig -AccountType Standard_LRS  `
    -Location $location -CreateOption Import `
    -SourceUri $urlOfUploadedImageVhd) `
    -ResourceGroupName $rgName


$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_A2"
$vNET_resourceGroupName = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a vNET Group" -OutputMode Single).ResourceGroupName
$virtualNetworkName = (Get-AzVirtualNetwork -ResourceGroupName $vNET_resourceGroupName | Select-Object Name | Out-GridView -Title "Select a Virtual Network" -OutputMode Single).Name
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $vNET_resourceGroupName
$subnet = ($vnet.Subnets | Select Name,ID| Out-GridView -Title "Select a subnet" -OutputMode Single).Id
$nic = New-AzNetworkInterface -Name $nicName  -ResourceGroupName $rgName -Location $location -SubnetId $subnet


$vm = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
$vm = Set-AzVMOSDisk -VM $vm -ManagedDiskId $osDisk.Id -StorageAccountType Standard_LRS `
    -DiskSizeInGB 128 -CreateOption Attach -Windows

New-AzVM -ResourceGroupName $rgName -Location $location -VM $vm


$imageConfig = New-AzImageConfig -Location $location
$imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsType Windows -BlobUri $urlOfUploadedImageVhd
$image = New-AzImage -ImageName $imageName -ResourceGroupName $rgName -Image $imageConfig

#Provide the name of an existing virtual network where virtual machine will be created
$vNET_resourceGroupName = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a vNET Group" -OutputMode Single).ResourceGroupName
$virtualNetworkName = (Get-AzVirtualNetwork -ResourceGroupName $vNET_resourceGroupName | Select-Object Name | Out-GridView -Title "Select a Virtual Network" -OutputMode Single).Name
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $vNET_resourceGroupName
$subnet = ($vnet.Subnets | Select Name,ID| Out-GridView -Title "Select a subnet" -OutputMode Single).Id


$nic = New-AzNetworkInterface -Name $nicName  -ResourceGroupName $rgName -Location $location -SubnetId $subnet

$cred = Get-Credential

$vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize

$vm = Set-AzVMSourceImage -VM $vm -Id $image.Id

$vm = Set-AzVMOSDisk -VM $vm -CreateOption FromImage -Caching ReadWrite

$vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $computerName -Credential $cred #-ProvisionVMAgent -EnableAutoUpdate

$vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id

New-AzVM -VM $vm -ResourceGroupName $rgName -Location $location

