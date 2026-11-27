targetScope = 'resourceGroup'

@description('Neighbour only. This exercise is ANSWER.md, not a template puzzle.')
param location string = resourceGroup().location

output location string = location
