targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'eastus'

output location string = location

// ---- Your resources go below this line. ----

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'lagb-a03-e01-rg-at-subscription-scope'
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-e01-rg-at-subscription-scope'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}
