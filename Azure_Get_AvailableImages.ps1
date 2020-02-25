

$loc = (Get-AzLocation | Sort Location | Select-Object Location | Out-GridView -Title "Select a location" -OutputMode Single).Location

#Find all the available publishers
$pubName = (Get-AzVMImagePublisher -Location $loc | Sort PublisherName | Select-Object PublisherName | Out-GridView -Title "Select a publisher" -OutputMode Single).PublisherName

$offerName = (Get-AzVMImageOffer -Location $loc -Publisher $pubName | Select-Object Offer | Out-GridView -Title "Select a offer" -OutputMode Single).Offer

$sku = (Get-AzVMImageSku -Location $loc -Publisher $pubName -Offer $offerName | Select-Object Skus | Out-GridView -Title "Select a sku" -OutputMode Single).skus

Get-AzVMImage -Location $loc -PublisherName $pubName -Offer $offerName -Skus $sku
