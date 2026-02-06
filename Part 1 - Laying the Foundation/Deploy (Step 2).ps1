# Connect to Azure
Write-Host "Logging into Azure..." -ForegroundColor Cyan
Connect-AzAccount

# Select AZ subscription (Recommended to use dedicated AVD subscription)
Write-Host "Selecting Azure subscription..." -ForegroundColor Cyan
Get-AzSubscription | Out-GridView -PassThru | Select-AzSubscription

# Deploy Bicep Config
Write-Host "Deploying Bicep Code..." -ForegroundColor Cyan
New-AzSubscriptionDeployment `
  -TemplateFile '.\main.bicep' `
  -TemplateParameterFile '.\main.bicepparam' `
  -location 'uksouth' `
  -Name 'AIBCoreDeployment'