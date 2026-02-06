// Deploys all resources for Azure Image Builder Environment.
// Author: Alex Durrant
// Version: 1.0
// Date: 24.06.2025

/*##################
#    Parameters    #
##################*/

targetScope = 'subscription'

// global parameters
@description('The prefix name of the client')
param clientPrefix string
@description('The prefix name of the location, e.g uks = UK South')
param NameLocationPrefix string


///////// Resource Group Module
@minLength(5)
@description('Name of the resource group for AIB? Example rg-aib-01')
param aibrgname string
@minLength(5)
@description('Name of the staging resource group for AIB? Example rg-aibstaging-01')
param aibstagingrgname string
@description('Tags to apply to the resource groups')
param rgtags object = {}

///////// AIB Module
// Storage Account
@description('The prefix name of the storage account')
param storageNamePrefix string

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
@description('Name of Storage Container')

param storagecontainerName string
@description('The prefix name of the User Assigned Managed Identity account, e.g. uami')
param useridprefix string 

// Azure Compute Gallery
@description('The prefix name of the Azure Compute Gallery, e.g. acg')
param galleryPrefix string 

@description('The prefix name of the image within ACG, e.g. imgd')
param imagePrefix string 

@description('Name of the middle part of the image, e.g. Win11AVD')
param imageNameShort string

// Assigning role permissions
// Storage Blob Data Reader
@description('Enter in role ID of Storage Blob Data Reader')
param storageblobdatareaderRoleDefinitionId string

// Managed Identity Operator
@description('Enter in role ID of Managed Operator Role')
param managedIdentityOperatorRoleId string

// Contributor role id
@description('Enter in role ID of Contributor Role, used for the staging RG')
param contributorRoleId string

/*#################
#    Variables    #
#################*/


/*##################  
#    Resources    #
##################*/
// RG Module
module resourceGroups 'ResourceGroups.bicep' = {
  name: 'rg-deploy'
  scope: subscription()
  params: {
    aibrgname: aibrgname
    aibstagingrgname: aibstagingrgname
    rgtags: rgtags
  }
}

// AIB Module
module imageBuilder 'AIB.bicep' = {
  name: 'imagebuilder-deploy'
  scope: resourceGroup(aibrgname)
  params: {
    clientPrefix: clientPrefix
    NameLocationPrefix: NameLocationPrefix 
    storageAccountType: storageAccountType
    storageNamePrefix: storageNamePrefix
    storagecontainerName: storagecontainerName
    useridprefix: useridprefix
    galleryPrefix: galleryPrefix
    imageNameShort: imageNameShort
    imagePrefix: imagePrefix
    storageblobdatareaderRoleDefinitionId: storageblobdatareaderRoleDefinitionId
  }
  dependsOn: [
    resourceGroups
  ]
}

// Create Custom Roles
module customRole 'CustomRoleDefinition.bicep' = {
  name: 'create-aib-custom-role'
  scope: subscription()
  params: {
    clientPrefix: clientPrefix
    assignableScope: resourceGroups.outputs.aibrgId
  }
}


// AssignSubRoles.bicep
module assignOperator 'AssignSubRoles.bicep' = {
  name: 'assign-managed-id-operator'
  scope: subscription()
  params: {
    principalId: imageBuilder.outputs.managedIdentityPrincipalId
    roleDefinitionId: managedIdentityOperatorRoleId
  }
}

// Assign UAMI to custom role
// AssignRGRoles.bicep
module assignCustomRole 'AssignRGRoles.bicep' = {
  name: 'assign-custom-aib-role'
  scope: resourceGroup(aibrgname)
  params: {
    principalId: imageBuilder.outputs.managedIdentityPrincipalId
    roleDefinitionId: split(customRole.outputs.roleDefinitionId, '/')[6]
  }
}

// Assign UAMI to staging rg as contributor
// AssignRGRoles.bicep
module assignContributortoStaging 'AssignRGRoles.bicep' = {
  name: 'assign-contributor-aib-staging-role'
  scope: resourceGroup(aibstagingrgname)
  params: {
    principalId: imageBuilder.outputs.managedIdentityPrincipalId
    roleDefinitionId: contributorRoleId
  }
}

/*################
#    Outputs    #
################*/
@description('AIB Resource Group Name')
output aibrgName string = resourceGroups.outputs.aibrgName
@description('AIB Resource Group ID')
output aibrgId string = resourceGroups.outputs.aibrgId
@description('AIB Staging Resource Group Name')
output aibstagingrgName string = resourceGroups.outputs.aibstagingrgName
@description('AIB Staging Resource Group ID')
output aibstagingrgId string = resourceGroups.outputs.aibstagingrgId
@description('AIB Storage Account Name')
output storageAccountName string = imageBuilder.outputs.storageAccountName
@description('AIB Storage Account ID')
output storageAccountId string = imageBuilder.outputs.storageAccountId
@description('Storage Account Endpoints')
output storageAccountEndpoint object = imageBuilder.outputs.storageAccountEndpoints
@description('AIB Storage Account Container Name')
output ContainerName string = imageBuilder.outputs.ContainerName
@description('AIB Managed Identity ID')
output managedIdentityId string = imageBuilder.outputs.managedIdentityId
@description('AIB Custom Role Definition ID')
output CustomRoleId string = customRole.outputs.roleDefinitionId
