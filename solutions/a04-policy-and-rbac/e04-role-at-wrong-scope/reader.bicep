targetScope = 'resourceGroup'

@description('Object ID of the principal that receives Reader. All-zero default is for PSRule expansion, not a live principal.')
param principalId string = '00000000-0000-0000-0000-000000000000'

@description('Principal type for the assignment (User, Group, or ServicePrincipal).')
param principalType string = 'User'

var readerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, readerRoleId)
  properties: {
    roleDefinitionId: readerRoleId
    principalId: principalId
    principalType: principalType
  }
}
