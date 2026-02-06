<#
.SYNOPSIS
    Azure Virtual Desktop (AVD) Prerequisites Script

.DESCRIPTION
    This script registers providers within Azure subscription(s) for deploying Azure Virtual Desktop (AVD) via IaC (BICEP).
    It includes:
        - Logging into Azure and selecting a subscription
        - Registering required resource providers
.NOTES
    Author    : Alex Durrant
    Version   : 1.0
    Date      : 25th June 2025
    Contact   : Alex Durrant
    Usage     : Run this script in PowerShell 7 with the necessary owner permissions in the target Azure subscription.

.CHANGELOG
    1.0 - 25-06-2025 - Initial version by Alex Durrant
#>

# Connect to Azure
Write-Host "Logging into Azure..." -ForegroundColor Cyan
Connect-AzAccount

# Select AZ subscription (Recommended to use dedicated AVD subscription)
Write-Host "Selecting Azure subscription..." -ForegroundColor Cyan
Get-AzSubscription | Out-GridView -PassThru | Select-AzSubscription

# Enabling Resource Providers
Write-Host "Registering required resource providers..." -ForegroundColor Cyan
$providerNamespaces = @(
    'Microsoft.Compute',
    'Microsoft.KeyVault',
    'Microsoft.Storage',
    'Microsoft.VirtualMachineImages',
    'Microsoft.Network',
    'Microsoft.ManagedIdentity',
    'Microsoft.DesktopVirtualization',
    'Microsoft.GuestConfiguration',
    'Microsoft.ContainerInstance'
)
foreach ($providerNamespace in $providerNamespaces) {
    $resourceProvider = Get-AzResourceProvider -ProviderNamespace $providerNamespace
    if ($resourceProvider.RegistrationState -ne 'Registered') {
        Write-Host "Registering $providerNamespace..." -ForegroundColor Yellow
        Register-AzResourceProvider -ProviderNamespace $providerNamespace
    }
}
# Register provider features
Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

# Check
Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

Write-Host "Wait 15 minutes before deploying Bicep code" -ForegroundColor Yellow