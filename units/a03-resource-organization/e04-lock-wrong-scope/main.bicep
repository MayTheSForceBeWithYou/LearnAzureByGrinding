targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'eastus'

@description('Name of the resource group the lock is supposed to protect.')
param rgName string = 'lagb-a03-e04'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-e04-lock-wrong-scope'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}

resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'lagb-cannotdelete'
  properties: {
    level: 'CanNotDelete'
    notes: 'Intended to protect the resource group, not the subscription.'
  }
}
