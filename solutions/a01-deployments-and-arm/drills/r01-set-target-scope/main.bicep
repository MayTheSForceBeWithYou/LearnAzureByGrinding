targetScope = 'subscription'

// ---- Your resources go below this line. ----
@description('Name of the resource group to create.')
param rgName string = 'lagb-a01-r01'

@description('Azure region for the resource group.')
param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}
