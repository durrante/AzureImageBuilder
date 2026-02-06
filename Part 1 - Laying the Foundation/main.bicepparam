using './main.bicep'
/*#######################
#         Global        #
#######################*/
param clientPrefix = 'ADU' //e.g. 'ADU' something unique to the client, two or three characters.
param NameLocationPrefix = 'uks'

/*#######################
#   Resource Group Module  #
#######################*/
param aibrgname = 'rg-aib-01'
param aibstagingrgname = 'rg-aibstaging-01'
param rgtags = {
  ApplicationName: 'Azure Virtual Desktop'
  ApproverName: 'ApproverPerson'
  BusinessUnit: 'IT'
  Environment: 'Production'
  Owner: 'OwnerPerson'
}

/*#######################
#   AIB Module          #
#######################*/
// Storage account
param storageNamePrefix = 'stg'
param storageAccountType = 'Standard_LRS'
param storagecontainerName ='azureimagebuilder'

// Azure Compute Gallery
param galleryPrefix = 'acg'
param imagePrefix = 'imgd'
param imageNameShort = 'Win11AVD'

// managed identity
param useridprefix = 'id'

// Assigning role permissions
// Storage Blob Data Reader
param storageblobdatareaderRoleDefinitionId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
// Managed Identity Operator
param managedIdentityOperatorRoleId = 'f1a07417-d97a-45cb-824c-7a7467783830'
// Contributor role id
param contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
