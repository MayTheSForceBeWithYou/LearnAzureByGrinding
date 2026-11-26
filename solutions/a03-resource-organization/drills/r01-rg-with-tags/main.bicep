targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'eastus'

output location string = location

// ---- Your resources go below this line. ----

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'lagb-a03-r01-rg-with-tags'
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-r01-rg-with-tags'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}
