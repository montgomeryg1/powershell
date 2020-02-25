$vaultName = "vault"
$resourceGroup = "resource_group"
$location = "northeurope"
$secretName = "localAdminPassword"

New-AzResourceGroup `
  -Name $resourceGroup `
  -Location $location

New-AzKeyVault `
  -VaultName $vaultName `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -EnabledForTemplateDeployment

$secretValue = ConvertTo-SecureString -String (New-Guid).Guid -AsPlainText -Force

Set-AzureKeyVaultSecret `
  -VaultName $vaultName `
  -Name $secretName `
  -SecretValue $secretValue