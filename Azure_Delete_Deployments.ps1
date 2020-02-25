$resourceGroupName = "myResourceGroup"
$count = 0

$deployments = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName
$deploymentsToDelete = $deployments #| where { $_.Timestamp -lt ((get-date).AddHours(-1)) }
$deploymentCount = $deploymentsToDelete.Count
Write-Output "Deployments to delete $deploymentCount"

foreach ($deployment in $deploymentsToDelete) {
    $count++
    $name = $deployment.DeploymentName
    Start-Job { param ($ctx,$resourceGroupName,$name)
        Set-AzContext $ctx
        Remove-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -DeploymentName $name

    } -ArgumentList ($(Get-AzContext),$resourceGroupName,$name)
    if(!($count%20)){Get-Job | Wait-Job | Out-Null}
    if ((Get-Job).State -match "Failed"){exit 1}
}
