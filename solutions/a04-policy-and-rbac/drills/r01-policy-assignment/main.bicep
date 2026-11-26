targetScope = 'resourceGroup'

@description('Locations the assignment allows.')
param allowedLocations array = [
  'eastus'
]

output allowedLocations array = allowedLocations

// ---- Your resources go below this line. ----

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lagb-allowed-locations'
  properties: {
    displayName: 'Allowed locations'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}
