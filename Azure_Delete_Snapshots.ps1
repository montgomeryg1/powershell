#Provide the subscription Id
$subscriptionId = (Get-AzSubscription | Select-Object Name,Id | Out-GridView -Title "Select a Subscription" -OutputMode Single).Id

Select-AzSubscription -SubscriptionId $subscriptionId

$rgName = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group" -OutputMode Single).ResourceGroupName

Get-AzSnapshot -ResourceGroupName $rgName | Where-Object {$_.TimeCreated -lt ((Get-Date).AddDays(-7))} | Remove-AzSnapshot -Force