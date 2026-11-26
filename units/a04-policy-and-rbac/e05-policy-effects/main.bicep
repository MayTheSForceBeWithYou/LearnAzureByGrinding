targetScope = 'resourceGroup'

@description('Locations the neighbour assignment allows.')
param allowedLocations array = [
  'eastus'
]

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lagb-a04-e05-allowed-locations'
  properties: {
    displayName: 'Neighbour: Allowed locations (eastus)'
    policyDefinitionId: subscriptionResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}
