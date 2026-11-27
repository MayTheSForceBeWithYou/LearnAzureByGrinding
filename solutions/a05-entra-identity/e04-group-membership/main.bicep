targetScope = 'resourceGroup'

@description('Neighbour only. Predict membership from fixtures/users-and-groups.json into ANSWER.md.')
param location string = resourceGroup().location

output location string = location
