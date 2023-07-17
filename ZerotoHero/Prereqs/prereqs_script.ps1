### Azure Image Builder - Prereqs Run through ###
## Install \ import AZ Modules and Signin
    # Ensure that you have PowerShell 7 installed, if not, install it here: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3#installing-the-msi-package
    # check PS Version
    $PSVersionTable.PSVersion

    # Check if the Az PowerShell module is installed
    if (!(Get-InstalledModule -Name Az -ErrorAction SilentlyContinue)) {
        # If not installed, install it
        Write-Output "Azure PowerShell module not found. Installing..."
        Install-Module -Name Az.Compute -AllowClobber -Force
    } else {
        # If installed, check if it's up to date
        $CurrentVersion = (Get-InstalledModule -Name Az).Version
        $LatestVersion = (Find-Module -Name Az).Version
        if ($CurrentVersion -lt $LatestVersion) {
            # If not up to date, update it
            Write-Output "Azure PowerShell module is not up to date. Updating..."
            Install-Module -Name Az.Compute -AllowClobber -Force
        } else {
            Write-Output "Azure PowerShell module is up to date."
        }
    }

    # Check if the Az module is imported into the current session
    if (!(Get-Module -Name Az)) {
        # If not imported, import it
        Write-Output "Az module not found in the current session. Importing..."
        Import-Module -Name Az
    } else {
        Write-Output "Az module is already imported into the current session."
    }

    # Log In
    Connect-AzAccount

    # View current subscription
    Get-AzContext

    # Set subscription (use this to change subscription, if needed - Note: Window appears in background)
    Get-AzSubscription | Out-Gridview -PassThru | Select-AzSubscription

## Set Resource Providers
    # Define an array of provider namespaces
    $providerNamespaces = @(
        'Microsoft.Compute', 
        'Microsoft.KeyVault', 
        'Microsoft.Storage', 
        'Microsoft.VirtualMachineImages', 
        'Microsoft.Network', 
        'Microsoft.ManagedIdentity'
    )

    # Create an empty array to store the names of the registered resource providers
    $registeredProviders = @()

    # Loop through each provider namespace
    foreach ($providerNamespace in $providerNamespaces) {
        # Get the resource provider
        $resourceProvider = Get-AzResourceProvider -ProviderNamespace $providerNamespace

        # Check if the resource provider is not registered
        if ($resourceProvider.RegistrationState -ne 'Registered') {
            # If not registered, output the name and register the resource provider
            Write-Output "Resource provider '$providerNamespace' is not registered. Registering..."
            $resourceProvider | Register-AzResourceProvider

            # Add the name of the resource provider to the array of registered resource providers
            $registeredProviders += $providerNamespace
        }
    }

    # Output the names of the resource providers that were registered
    if ($registeredProviders.Count -gt 0) {
        Write-Output "The following resource providers were registered:"
        foreach ($provider in $registeredProviders) {
            Write-Output $provider
        }
    } else {
        Write-Output "All resource providers are already registered."
    }

## Variables for Managed Identity
    # Get location for desired Azure Region (Use this only if you're unsure which location name to use for the next steps)
    Get-AzLocation | Select-Object Location, DisplayName, PhysicalLocation, GeographyGroup | Sort-Object Location

    # Destination image resource group name # Change this to match your environment standards, e.g. rg-aib-uks-001
    $AIBResourceGroup = 'change me'

    # Azure region # change this as required.
    $location = 'uksouth'

    # Tags # these are listed as example only, change them to meet your needs
    $Tags = @{
        "ApplicationName" = "AIB"
        "BusinessUnit" = "IT"
        "Env" = "Prod"
        "DR" = "Essential"
        "Owner" = "youremail@domain.com"
    }

    #AIBRoleIdentityName
    $imageRoleDefName = "Azure Image Builder Image Def Role"
    #AIB Managed Identity Name # change this, must be unique, e.g. AIBIdentity001 or date stamp it.
    $identityName = "Change me"

    # Your Azure Subscription ID
    $subscriptionID = (Get-AzContext).Subscription.Id
    Write-Output $subscriptionID

## Create User Identity
    # Create Resource Group
    New-AzResourceGroup -Name $imageResourceGroup -Location $location -Tag $Tags

    # Create Managed Identity
    New-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $identityName -Location $location -Tag $Tags

    # Store Identity Resource and Principle ID's in variables
    $identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $identityName).Id
    $identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $AIBResourceGroup -Name $identityName).PrincipalId

## Assign Permissions to Managed Identity
    # Download and Modify Permissions JSON for AIB Role
    $myRoleImageCreationUrl = 'https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json'
    $myRoleImageCreationPath = "myRoleImageCreation.json"

    Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing

    $Content = Get-Content -Path $myRoleImageCreationPath -Raw
    $Content = $Content -replace '<subscriptionID>', $subscriptionID
    $Content = $Content -replace '<rgName>', $AIBResourceGroup
    $Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
    $Content | Out-File -FilePath $myRoleImageCreationPath -Force

    # Create the AIB Role Definition
    New-AzRoleDefinition -InputFile $myRoleImageCreationPath -Verbose

    # Assign the AIB Managed Identity to the AIB Definition (Note: if you receive an error of cannot find role definition, wait 30 seconds and try again.)
    $RoleAssignParams = @{
        ObjectId = $identityNamePrincipalId
        RoleDefinitionName = $imageRoleDefName
        Scope = "/subscriptions/$subscriptionID/resourceGroups/$AIBResourceGroup"
      }
      New-AzRoleAssignment @RoleAssignParams

## Create vNET for AIB
    # vNET Variables (Note: Change where required).
    $vnetName = "vnet-aib-uks-001"
    $subnetName = "AIBSubnet"
    $ResourceGroupName = $ImageResourceGroup

    # Create a subnet configuration
    $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 192.168.1.0/24
    
    # Create a virtual network
    New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
      -Name $vnetName -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig -Tag $tags

## Create Storage Account
    # Define parameters for the storage account
    $storageAccountName = "mystorageaccount" # Change this, storage account name must be UNIQUE.
    $storageAccountSku = "Standard_LRS"
    
    # Create a storage account with no public access
    New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName `
        -Location $location -SkuName $storageAccountSku -EnableHttpsTrafficOnly $true `
        -AllowBlobPublicAccess $false -Tag $tags
    
    # Allow access from the previously created virtual network (Note: you may want to add your external IP address too to upload content)
    Set-AzStorageAccountNetworkRuleSet -ResourceGroupName $resourceGroupName -Name $storageAccountName `
        -DefaultAction Deny -VirtualNetworkResourceId $(Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName).Id
    
    # Get the storage account context
    $ctx = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
    
    # Define parameters for the blob container
    $containerName = "AzureImageBuilder"
    
    # Create a blob container with no public access
    New-AzStorageContainer -Name $containerName -Context $ctx -Permission Blob
