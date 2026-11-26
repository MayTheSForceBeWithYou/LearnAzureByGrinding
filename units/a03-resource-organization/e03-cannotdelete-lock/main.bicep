targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'eastus'

@description('Name of the resource group the lock must target.')
param rgName string = 'lagb-a03-e03'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-e03-cannotdelete-lock'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}

// ---- Your resources go below this line. ----
