#Requires -Modules ImportExcel
$resources = @()
$rgNames =  (Get-AzureRmResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group" -OutputMode Multiple).ResourceGroupName
$resources = Get-AzureRmResource | Where {$rgNames -contains $_.ResourceGroupName}
$resources | Sort Name | Export-Excel -Path AzureReources.xlsx -TableStyle Dark1 -WorkSheetname $rgName -TableName $rgName

