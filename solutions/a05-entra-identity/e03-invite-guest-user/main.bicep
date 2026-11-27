targetScope = 'resourceGroup'

@description('Neighbour only. This exercise is portal work in the A05 test tenant, recorded in ANSWER.md.')
param location string = resourceGroup().location

output location string = location
