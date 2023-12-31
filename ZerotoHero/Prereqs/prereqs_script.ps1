### Azure Image Builder - Prereqs Run through ###
## Install \ import AZ Modules and Signin
    # Ensure that you have PowerShell 7 installed, if not, install it here: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3#installing-the-msi-package
    # check PS Version
    $PSVersionTable.PSVersion

    # Check if the Az PowerShell module is installed
    if (!(Get-InstalledModule -Name Az -ErrorAction SilentlyContinue)) {
        # If not installed, install it
        Write-Output "Azure PowerShell module not found. Installing..."
        Install-Module -Name Az -Repository PSGallery -Force
    } else {
        # If installed, check if it's up to date
        $CurrentVersion = (Get-InstalledModule -Name Az).Version
        $LatestVersion = (Find-Module -Name Az).Version
        if ($CurrentVersion -lt $LatestVersion) {
            # If not up to date, update it
            Write-Output "Azure PowerShell module is not up to date. Updating..."
            Update-Module Az.* -Force
        } else {
            Write-Output "Azure PowerShell module is up to date."
        }
    }

    # Check if the Az module is imported into the current session
    if (!(Get-Module -Name Az)) {
        # If not imported, import it
        Write-Output "Az module not found in the current session. Importing..."
        Import-Module -Name Az -force
    } else {
        Write-Output "Az module is already imported into the current session."
    }

    # Log In
    Connect-AzAccount

    # View current subscription
    Get-AzContext

    # Set subscription (use this to change subscription, if needed - Note: Window appears in background)
    Get-AzSubscription | Out-Gridview -PassThru | Select-AzSubscription

## Global Variables
    # Get location for desired Azure Region (Use this only if you're unsure which location name to use for the next steps)
    Get-AzLocation | Select-Object Location, DisplayName, PhysicalLocation, GeographyGroup | Sort-Object Location

    # Destination image resource group name 
    $ResourceGroupName = 'rg-aib-uks-002' # Change this to match your environment standards, e.g. rg-aib-uks-001

    # Azure region 
    $location = 'uksouth' # change this as required.

    # Tags # these are listed as example only, change them to meet your needs
    $Tags = @{
        "ApplicationName" = "AIB"
        "BusinessUnit" = "IT"
        "Env" = "Prod"
        "DR" = "Essential"
        "Owner" = "Alex.Durrant@letsconfigmgr.com"
    }

## Create Resource Group
    New-AzResourceGroup -Name $ResourceGroupName -Location $location -Tag $Tags

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

## Create Azure Compute Gallery
    #ACG Variables
    $GalleryName = 'ACGUKS002' # Change this to your desired gallery name
    $imageDefName = 'Windows11AVD'# Change this to your desired image definition name
    $GalleryParams = @{
        GalleryName = $GalleryName
        ResourceGroupName = $ResourceGroupName
        Location = $location
        Name = $imageDefName
        OsState = 'generalized'
        OsType = 'Windows' # Linux or Windows
        Publisher = 'LetsConfigMgr' # Replace with your desired publisher name
        Offer = 'Windows11Multi' # Replace with your desired offer name
        Sku = 'M365Gen2'# Replace with your desired SKU name
        Tag = $Tags
        HyperVGeneration = "V2"
        MinimumMemory = 8
        MinimumVCPU = 2
        disallowedDiskType = @("Standard_LRS")
        Feature = @{Name='SecurityType';Value='TrustedLaunch'}
           }

     # Create a new Azure Compute Gallery
    New-AzGallery -GalleryName $GalleryName -ResourceGroupName $ResourceGroupName -Location $location -Tag $Tags
    
     # Create a new Azure Compute Gallery Image Definition
    New-AzGalleryImageDefinition @GalleryParams

## Create vNET for AIB
    # vNET Variables (Note: Change where required).
    $vnetName = "vnet-aib-uks-002"
    $subnetName = "snet-aib-uks-001"

    # Create NSG
    $networkSecurityGroup = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
    -Location $location -Name "nsg-$subnetname"

    # Allow access from Proxy VM (aka load balancer) for private link via NSG
    Get-AzNetworkSecurityGroup -Name nsg-$subnetname -ResourceGroupName $ResourceGroupName  | Add-AzNetworkSecurityRuleConfig -Name AzureImageBuilderAccess -Description "Allow Image Builder Private Link Access to Proxy VM" -Access Allow -Protocol Tcp -Direction Inbound -Priority 400 -SourceAddressPrefix AzureLoadBalancer -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 60000-60001 | Set-AzNetworkSecurityGroup

    # Create a subnet configuration
    $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 192.168.1.0/24 -PrivateLinkServiceNetworkPoliciesFlag "Disabled" -NetworkSecurityGroup $networkSecurityGroup -ServiceEndpoint Microsoft.Storage
    
    # Create a virtual network
    New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
      -Name $vnetName -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig -Tag $tags 

## Create Storage Account
    # Define parameters for the storage account
    $storageAccountName = "staiblcmuks00005" # Change this, storage account name must be UNIQUE.
    $storageAccountSku = "Standard_LRS"
    
    # Create a storage account with no public access
    New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName `
        -Location $location -SkuName $storageAccountSku -EnableHttpsTrafficOnly $true `
        -AllowBlobPublicAccess $true -Tag $tags
    
    # Allow access from the previously created virtual network         
    $subnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $vnetName | Get-AzVirtualNetworkSubnetConfig -Name "$subnetName"
    Add-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroupName -Name $storageAccountName -VirtualNetworkResourceId $subnet.Id

    # Add current client external IP to Storage Firewall (Note: This is completely optional and may not be required)
    $CurrentExternalIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
    Add-AzStorageAccountNetworkRule -ResourceGroupName $ResourceGroupName -Name $storageAccountName -IPAddressOrRange $CurrentExternalIP

    # Set Storage Account Network Firewall to Deny (aka Enabled from selected networks and IP address as previously network rules have been defined)
    Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $resourceGroupName -Name $storageAccountName -DefaultAction Deny

    # Get the storage account context
    $ctx = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
    
    # Define parameters for the blob container
    $containerName = "azureimagebuilder" # Update this to match your requirements, Note: uppercase characters are not allowed.
    
    # Create a blob container with no public access
    New-AzStorageContainer -Name $containerName -Context $ctx -Permission Blob

## Create Managed Identity & AIB Roles
    # AIBRoleIdentityName
    $date = Get-Date -Format "dd-MM-yyyy"
    $imageRoleDefName="Azure Image Builder Image Def Role" + "-" + $date

    # AIB Managed Identity Name # change this, must be unique, e.g. AIBIdentity001 or date stamp it.
    $date = Get-Date -Format "dd-MM-yyyy"
    $identityName = "AIBIdentity001" + "-" + $date

    # Your Azure Subscription ID
    $subscriptionID = (Get-AzContext).Subscription.Id
    Write-Output $subscriptionID

    #  Create AIB Role and assign permissions
    New-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $identityName -Location $location -Tag $Tags

    # Store Identity Resource and Principle ID's in variables
    $identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $identityName).Id
    $identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $identityName).PrincipalId

    # Assign AIB Permissions to Managed Identity
    # Download and Modify Permissions JSON for AIB Role
    $myRoleImageCreationUrl = 'https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json'
    $myRoleImageCreationPath = "myRoleImageCreation.json"

    Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing

    $Content = Get-Content -Path $myRoleImageCreationPath -Raw
    $Content = $Content -replace '<subscriptionID>', $subscriptionID
    $Content = $Content -replace '<rgName>', $ResourceGroupName
    $Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
    $Content | Out-File -FilePath $myRoleImageCreationPath -Force

    # Create the AIB Role Definition
    New-AzRoleDefinition -InputFile $myRoleImageCreationPath -Verbose

    # Assign the AIB Managed Identity to the AIB Definition (Note: if you receive an error of cannot find role definition, wait 30 seconds and try again.)
    $RoleAssignParams = @{
        ObjectId = $identityNamePrincipalId
        RoleDefinitionName = $imageRoleDefName
        Scope = "/subscriptions/$subscriptionID/resourceGroups/$ResourceGroupName"
      }
      New-AzRoleAssignment @RoleAssignParams

    # Assign vNet permissions to Managed Identity  
    # Use a web request to download the sample JSON description
    $sample_uri="https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json"
    $role_definition="aibRoleNetworking.json"
    
    Invoke-WebRequest -Uri $sample_uri -Outfile $role_definition -UseBasicParsing
    
    # Create a unique role name to avoid clashes in the same AAD domain
    $date = Get-Date -Format "dd-MM-yyyy"
    $networkRoleDefName="Azure Image Builder Service Networking Role" + "-" + $date
    
    # Update the JSON definition placeholders with variable values
    ((Get-Content -path $role_definition -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $role_definition
    ((Get-Content -path $role_definition -Raw) -replace '<vnetRgName>', $ResourceGroupName) | Set-Content -Path $role_definition
    ((Get-Content -path $role_definition -Raw) -replace 'Azure Image Builder Service Networking Role',$networkRoleDefName) | Set-Content -Path $role_definition
    
    # Create a custom role from the aibRoleNetworking.json description file
    New-AzRoleDefinition -InputFile $role_definition
    
    # Get the user-identity properties
    $identityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $identityName).Id
    $identityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $identityName).PrincipalId
    
    # Assign the custom role to the user-assigned managed identity for Azure Image Builder
    $parameters = @{
        ObjectId = $identityNamePrincipalId
        RoleDefinitionName = $networkRoleDefName
        Scope = '/subscriptions/' + $subscriptionID+ '/resourceGroups/' + $ResourceGroupName
    }
    
    New-AzRoleAssignment @parameters

    # Assign Permissions to Storage Access to Managed Identity
    # Get storage account resource ID
    $storageAccountResourceId = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Id

    # Assign 'Storage Blob Data Reader' role to the AIBIdentity for the storage account
    New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName 'Storage Blob Data Reader' -Scope $storageAccountResourceId

    # Assign 'Managed Identity Operator' role to the AIBIdentity at the subscription level
    New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName 'Managed Identity Operator' -Scope "/subscriptions/$subscriptionID"
