@description('The Principal ID of the Managed Identity')
param principalId string

@description('The Role Definition ID to assign')
param roleDefinitionId string

targetScope = 'subscription'

resource assignRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, roleDefinitionId)
  scope: subscription()
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}
