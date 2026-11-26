targetScope = 'resourceGroup'

@description('Locations the assignment allows.')
param allowedLocations array = [
  'eastus'
]

output allowedLocations array = allowedLocations

// ---- Your resources go below this line. ----
