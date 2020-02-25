#Requires -Modules Az

$apiManager = Get-AzApiManagement | Select-Object Name,ResourceGroupName | Out-GridView -Title "Select API Manager" -OutputMode Single
$context = New-AzApiManagementContext -resourcegroup $apiManager.ResourceGRoupName -servicename $apiManager.Name
$url = (Get-AzApiManagementBackend -Context  $context  | Select Url | Out-GridView -Title "Select URL Backend" -OutputMode Single).url
New-AzApiManagementBackend -Context  $context -Url $url -Protocol http -SkipCertificateChainValidation $true
Get-AzApiManagementBackend -Context  $context  | Select Url

