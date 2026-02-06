@description('The prefix name of the client, e.g. ADU')
param clientPrefix string

@description('The assignable scope for the custom role (usually a resource group or subscription).')
param assignableScope string

// Generate a unique and consistent role definition ID
var roleDefinitionGuid = guid('${clientPrefix}-aib-custom-role')

targetScope = 'subscription'

resource customRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefinitionGuid
  properties: {
    roleName: '[${toUpper(clientPrefix)}] Azure Image Builder Image Role'
    description: 'Image Builder access to create resources for the image build'
    assignableScopes: [
      assignableScope
    ]
    permissions: [
      {
        actions: [
          'Microsoft.Compute/galleries/read'
          'Microsoft.Compute/galleries/images/read'
          'Microsoft.Compute/galleries/images/versions/read'
          'Microsoft.Compute/galleries/images/versions/write'
          'Microsoft.Compute/images/write'
          'Microsoft.Compute/images/read'
          'Microsoft.Compute/images/delete'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

// Optional output for debugging or future role assignment
@description('The name (GUID) of the created custom role')
output roleDefinitionId string = customRole.id
