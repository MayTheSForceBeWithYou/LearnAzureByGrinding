targetScope = 'subscription'

@description('Azure region for the guardrails resource group.')
param location string = 'eastus'

@description('Guardrails resource group name (prefix + capstone exercise id).')
param rgName string = 'lagb-c1-e01-governance-baseline'

@description('Object ID of the principal that receives Reader on the guardrails group.')
param principalId string = '00000000-0000-0000-0000-000000000000'

@description('Principal type for the assignment (User, Group, or ServicePrincipal).')
param principalType string = 'User'

@description('Capstone budget name. Not the A02 gate name lagb-monthly.')
param budgetName string = 'lagb-c1-baseline'

@description('Monthly amount for the capstone budget (> 0). The budget resource itself is free.')
@minValue(1)
param amount int = 25

@description('Email address for budget notifications.')
param contactEmail string = 'student@example.com'

@description('First day of the budget period (first of a month).')
param startDate string = utcNow('yyyy-MM-01')

@description('Course tags for the guardrails group (lab-up overwrites these with New-LabTags, including expires).')
param tags object = {
  course: 'LearnAzureByGrinding'
  unit: 'c1-landing-zone'
  exercise: 'c1-e01-governance-baseline'
  owner: 'n8'
  expires: '2026-12-31T00:00:00Z'
}

output location string = location
output rgName string = rgName
output principalId string = principalId
output principalType string = principalType
output budgetName string = budgetName
output amount int = amount
output contactEmail string = contactEmail
output startDate string = startDate
output tags object = tags

// ---- Your resources go below this line. ----

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

module cannotDelete 'lock.bicep' = {
  name: 'lagb-cannotdelete'
  scope: rg
  params: {
    lockName: 'lagb-cannotdelete'
    notes: 'Protect the capstone guardrails group from accidental deletion.'
  }
}

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'lagb-allowed-locations'
  properties: {
    displayName: 'Allowed locations'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: {
        value: [
          location
        ]
      }
    }
  }
}

module reader 'reader.bicep' = {
  name: 'lagb-reader'
  scope: rg
  params: {
    principalId: principalId
    principalType: principalType
  }
}

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      Actual_50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      Actual_80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      Actual_100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      Forecasted_80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Forecasted'
        contactEmails: [
          contactEmail
        ]
      }
      Forecasted_100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          contactEmail
        ]
      }
    }
  }
}
