
$rGroups =  (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group/s" -OutputMode Multiple).ResourceGroupName
$types = (Get-AzResource | Where-Object {$_.ResourceType -ne "Microsoft.Compute/virtualMachines" -and $rGroups -contains $_.ResourceGroupName} | Group-Object ResourceType | Sort-Object Name | Select-Object Name | Out-GridView -Title "Select Resource Types" -OutputMode Multiple).Name

foreach($type in $types)
{
    $items = Get-AzResource | Where-Object {$_.ResourceType -eq $type -and $rGroups -contains $_.ResourceGroupName}
    $items = $items | Out-GridView -Title "Select Resources from $rGroup" -OutputMode Multiple
    if($items){
        $i=1
        foreach($item in $items){
            try
            {
                Write-Progress -Activity "Removing resources" -status "Deleting resource $($item.Name)" -percentComplete ($i / $items.count*100)
                Remove-AzResource -ResourceName $item.Name -ResourceGroupName $item.ResourceGroupName -ResourceType $item.ResourceType -Force -ErrorAction Stop
                $i++
            }
            catch
            {
                Write-Warning $_
            }
        }
    }
}# foreach Resource Type
