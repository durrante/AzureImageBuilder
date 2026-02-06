// BICEP Module to create various Resource for use across various modules
// Author: Alex Durrant
// Version: 1.0
// Date: 24.06.2025

/*##################
#    Parameters    #
##################*/
@minLength(5)
@description('Name of the resource group for AIB? Example rg-aib-01')
param aibrgname string
@minLength(5)
@description('Name of the staging resource group for AIB? Example rg-aibstaging-01')
param aibstagingrgname string
@description('Tags to apply to the resource groups')
param rgtags object = {}

/*#################
#    Variables    #
#################*/

/*##################  
#    Resources    #
##################*/
targetScope = 'subscription'

// AIB Resource Group
resource aibrg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: aibrgname 
 location: deployment().location
 tags: rgtags
}

// AIB Staging Resource Group
resource aibstagingrg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: aibstagingrgname 
 location: deployment().location
 tags: rgtags
}

/*################
#    Outputs    #
################*/
@description('AIB Resource Group Name')
output aibrgName string = aibrg.name
@description('AIB Resource Group ID')
output aibrgId string = aibrg.id
@description('AIB Resource Group location')
output aibrglocation string = aibrg.location
@description('AIB Staging Resource Group Name')
output aibstagingrgName string = aibstagingrg.name
@description('AIB Staging Resource Group ID')
output aibstagingrgId string = aibstagingrg.id
@description('AIB Staging Resource Group location')
output aibstagingrglocation string = aibstagingrg.location

