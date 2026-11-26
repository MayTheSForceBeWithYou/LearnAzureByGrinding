targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'eastus'

output location string = location

// ---- Your resources go below this line. ----

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'lagb-a03-r02-lock-a-resource-group'
  location: location
  tags: {
    course: 'LearnAzureByGrinding'
    unit: 'a03-resource-organization'
    exercise: 'a03-r02-lock-a-resource-group'
    owner: 'n8'
    expires: '2026-12-31T00:00:00Z'
  }
}

module cannotDelete 'lock.bicep' = {
  name: 'lagb-cannotdelete'
  scope: rg
  params: {
    lockName: 'lagb-cannotdelete'
    notes: 'Protect the drill resource group from accidental deletion.'
  }
}
