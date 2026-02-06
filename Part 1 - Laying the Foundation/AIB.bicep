// BICEP Module to create Azure Image Builder Components
// Author: Alex Durrant
// Version: 1.1
// Date: 08.12.2025
// Notes: Added Lifecycle management to storage account
targetScope = 'resourceGroup'


/*##################
#    Parameters    #
##################*/
// global parameters
@description('The prefix name of the client')
param clientPrefix string
@description('The prefix name of the location, e.g uks = UK South')
param NameLocationPrefix string

// Storage Account parameters
@description('The prefix name of the storage account')
param storageNamePrefix string
@description('The storage account location.')
param location string = resourceGroup().location
@description('Storage Account type')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountType string
param storagecontainerName string

// Azure Compute Gallery
@description('The prefix name of the Azure Compute Gallery, e.g. acg')
param galleryPrefix string 

@description('The prefix name of the image within ACG, e.g. imgd')
param imagePrefix string 
@description('Name of the middle part of the image, e.g. Win11AVD')
param imageNameShort string

// User Managed Identity
@description('The prefix name of the User Assigned Managed Identity account, e.g. id')
param useridprefix string 

// Assigning role permissions
// Storage Blob Data Reader
@description('Enter in role ID of Storage Blob Data Reader')
param storageblobdatareaderRoleDefinitionId string

/*#################
#    Variables    #
#################*/

// Storage account
var storageAccountName = toLower('${storageNamePrefix}${clientPrefix}aib${NameLocationPrefix}01')

// Azure Compute Gallery
var galleryName = toLower('${galleryPrefix}${clientPrefix}${NameLocationPrefix}')
var imageName = toLower('${imagePrefix}-${imageNameShort}-01')

// managed identity
var aibuaminame = toLower('${useridprefix}-aib-${NameLocationPrefix}-01')

/*##################
#    Resources    #
##################*/
// Create Storage Account
resource aibstorageaccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
    }
    properties: {
        accessTier: 'Hot'
        allowBlobPublicAccess: true
        supportsHttpsTrafficOnly: true
        minimumTlsVersion: 'TLS1_2'
        encryption: {
            services: {
                blob: {
                    enabled: true
                }
                file: {
                    enabled: true
                }
                queue: {
                    enabled: true
                }
                table: {
                    enabled: true
                }
            }
        }    
    }
}
// Create Storage Blob Service
resource aibblobstorage 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
    parent: aibstorageaccount
    name: 'default'
    properties: {
        containerDeleteRetentionPolicy: {
            enabled: true
            days: 7
        }
        deleteRetentionPolicy: {
            enabled: true
            allowPermanentDelete: false
            days: 7
        }
    }
}
// Create Storage Container
resource aibcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
    parent: aibblobstorage
    name: toLower(storagecontainerName)
    properties: {
        publicAccess: 'None'
    }
}

// Create Storage Lifecycle Management Policy
resource aiblifecyclepolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2024-01-01' = {
    parent: aibstorageaccount
    name: 'default'
    properties: {
        policy: {
            rules: [
                {
                    enabled: true
                    name: 'Move AIB OldBuilds to Cold Storage'
                    type: 'Lifecycle'
                    definition: {
                        actions: {
                            baseBlob: {
                                tierToCold: {
                                    daysAfterModificationGreaterThan: 30
                                }
                            }
                        }
                        filters: {
                            blobTypes: [
                                'blockBlob'
                            ]
                            prefixMatch: [
                                'azureimagebuilder/Builds/OldVersions'
                            ]
                        }
                    }
                }
            ]
        }
    }
}

// Create Azure Compute Gallery
resource acg 'Microsoft.Compute/galleries@2024-03-03' = {
    name: galleryName
    location: location
    properties: {
        description: 'Used to manage, maintain and deploy Azure Virtual Desktop Images'
    }
}

resource image 'Microsoft.Compute/galleries/images@2024-03-03' = {
    name: imageName
    location: location
    parent: acg
    properties: { 
        hyperVGeneration: 'V2'
        architecture: 'x64'
        features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
      {
        name: 'IsAcceleratedNetworkSupported'
        value: 'True'
      }
      {
        name: 'IsHibernateSupported'
        value: 'True'
      }
    ]
    identifier: {
        sku: 'M365Gen2'
        offer: 'Windows11Multi' 
        publisher: clientPrefix
    }
    osState: 'Generalized'
    osType: 'Windows'
    recommended: {
        memory: {
            min: 16
        }
        vCPUs:{
            min: 4
        }
    }
    description: '${clientPrefix} Windows 11 AVD Image'
    disallowed: {
        diskTypes: [
            'Standard_LRS'
        ]
    }
    }
}

// Create User Managed Identity
resource aibuami 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
    name: aibuaminame
    location: location
}

// Assign role permissions to AIB Identity
// Storage Blob Data Reader
resource assignpermmissionsstorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(aibstorageaccount.id)
    scope: aibstorageaccount
    properties: {
        principalId: aibuami.properties.principalId
        // Storage Blob Reader Role ID (2a2b9908-6ea1-4ae2-8e65-a410df84e7d1)
        roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageblobdatareaderRoleDefinitionId)
    }
}

/*################
#    Outputs    #
################*/
@description('The Storage Account Name')
output storageAccountName string = aibstorageaccount.name

@description('The Storage Account ID')
output storageAccountId string = aibstorageaccount.id

@description('The Storage Account Endpoints')
output storageAccountEndpoints object = aibstorageaccount.properties.primaryEndpoints

@description('Container Name')
output ContainerName string = aibcontainer.name

@description('The User Managed Identity ID')
output managedIdentityId string = aibuami.id

@description('Principal ID')
output managedIdentityPrincipalId string = aibuami.properties.principalId
