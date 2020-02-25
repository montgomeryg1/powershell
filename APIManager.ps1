function Get-APIConfig{
    param(
        [string]$rgGroup,
        [string]$svcName
    )

    Write-Host $rgGroup
    Write-Host $svcName
    $ApiMgmtContext = $null
    $ApiMgmtContext = New-AzureRmApiManagementContext -ResourceGroupName $rgGroup -ServiceName $svcName
    $ApiMgmtContext

    Read-Host "Press Enter"
    $apis = Get-AzureRmApiManagementApi -Context $ApiMgmtContext
    try{Get-Item "$env:TEMP\$svcName" -ErrorAction Stop}catch{New-Item -ItemType Directory -Path "$env:TEMP\$svcName"}
    try{Get-Item "$env:TEMP\$svcName\current" -ErrorAction Stop}catch{New-Item -ItemType Directory -Path "$env:TEMP\$svcName\current"}
    try{Get-Item "$env:TEMP\$svcName\update" -ErrorAction Stop}catch{New-Item -ItemType Directory -Path "$env:TEMP\$svcName\update"}
    foreach($api in $apis){
        $apiId = $api.ApiId
        $apiName = $api.Name
        #Export-AzureRmApiManagementApi -Context $ApiMgmtContext -ApiId $apiId -SpecificationFormat "Wadl" -SaveAs "$env:TEMP\$svcName\$apiId.wadl" -Force
        try{Get-AzureRmApiManagementPolicy -Context $ApiMgmtContext -ApiId $apiId -SaveAs "$env:TEMP\$svcName\current\$apiName.policy.xml" -Force -ErrorAction Stop}
        catch{Get-AzureRmApiManagementPolicy -Context $ApiMgmtContext -ApiId $apiId -SaveAs "$env:TEMP\$svcName\current\$apiId.policy.xml" -Force -ErrorAction Stop}

    }
}


Clear-Host
Get-APIConfig -rgGroup "resource_group_name" -svcName "apimanager_name"
