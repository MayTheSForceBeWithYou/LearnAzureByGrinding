targetScope = 'resourceGroup'

@description('Object ID of the principal that receives Reader.')
param principalId string = '00000000-0000-0000-0000-000000000000'

@description('Principal type for the assignment (User, Group, or ServicePrincipal).')
param principalType string = 'User'

output principalId string = principalId
output principalType string = principalType

// ---- Your resources go below this line. ----
