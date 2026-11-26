targetScope = 'resourceGroup'

@description('Locations the assignment allows. The built-in parameter name is listOfAllowedLocations.')
param allowedLocations array = [
  'eastus'
]

output allowedLocations array = allowedLocations

// ---- Your resources go below this line. ----
