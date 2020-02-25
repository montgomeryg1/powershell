

$resourceGroupName = (Get-AzResourceGroup | Select-Object ResourceGroupName | Out-GridView -Title "Select a Resource Group" -OutputMode Single).ResourceGroupName

$apiManagerName = (Get-AzApiManagement -ResourceGroupName $resourceGroupName | Select-Object Name | Out-GridView -Title "Select a Resource Group" -OutputMode Single).Name
$apimContext = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apiManagerName
if (!(Test-Path $env:TEMP\${apiManagerName})) {
    New-Item -ItemType Directory -Path $env:TEMP\${apiManagerName}
}
#Get-AzApiManagementApi -Context $apimContext -Verbose
$apis = @("test", "stage", "prod")
foreach ($api in $apis) {
    Get-AzApiManagementPolicy -Context $apimContext -ApiId $api -SaveAs $env:TEMP\${apiManagerName}\${api}.xml -Force
    #Export-AzApiManagementApi -Context $apimContext -ApiId $api -SpecificationFormat "Wadl" -SaveAs C:\Users\montgomeryg\Desktop\API\${api}.wadl -Force
}

foreach ($api in $apis) {
    Set-AzApiManagementPolicy -Context $apimContext -ApiId $api -PolicyFilePath $env:TEMP\${apiManagerName}\${api}.xml
}

& explorer $env:TEMP
