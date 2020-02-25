[string]$group
[string]$resources

$objectId = Get-AzADGroup -SearchString $group | foreach {$_.Id}

$groups = Get-AzResourceGroup | where {$_.ResourceGroupName -match $resources} | foreach {$_.ResourceGroupName}

foreach($group in $groups)
{
    New-AzRoleAssignment -ObjectId $objectId.Guid -RoleDefinitionName "Reader" -ResourceGroupName $group # -Scope $subscription
}