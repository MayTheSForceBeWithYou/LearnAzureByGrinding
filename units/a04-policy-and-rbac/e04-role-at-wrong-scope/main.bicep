targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'eastus'

@description('Object ID of the principal that receives Reader.')
param principalId string = '00000000-0000-0000-0000-000000000000'

@description('Principal type for the assignment (User, Group, or ServicePrincipal).')
param principalType string = 'User'

@description('Name of the resource group the assignment is supposed to target.')
param rgName string = 'lagb-a04-e04'

var readerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a04-policy-and-rbac'
    exercise: 'a04-e04-role-at-wrong-scope'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}

resource reader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, readerRoleId)
  properties: {
    roleDefinitionId: readerRoleId
    principalId: principalId
    principalType: principalType
  }
}
