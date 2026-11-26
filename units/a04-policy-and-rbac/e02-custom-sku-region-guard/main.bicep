targetScope = 'subscription'

@description('Locations the lab guard allows.')
param allowedLocations array = [
  'eastus'
]

@description('VM SKUs the lab guard allows (B-series).')
param allowedVmSkus array = [
  'Standard_B1s'
  'Standard_B2s'
]

output allowedLocations array = allowedLocations
output allowedVmSkus array = allowedVmSkus

// ---- Your resources go below this line. ----
