targetScope = 'subscription'

@description('Azure region for the neighbour resource group.')
param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'lagb-a03-e05-example'
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-e05-subscriptions-and-management-groups'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}
