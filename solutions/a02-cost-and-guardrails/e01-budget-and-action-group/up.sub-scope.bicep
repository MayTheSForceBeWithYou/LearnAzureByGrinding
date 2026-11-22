targetScope = 'subscription'

@description('Guardrail tags from up.ps1: the New-LabTags set minus expires, with lifecycle=persistent.')
param guardrailTags object = {}

@description('Budget name; equals .lab-env.json budget.name (default lagb-monthly).')
param budgetName string = 'lagb-monthly'

@description('Monthly amount from .lab-env.json budget.amount. Must be > 0.')
@minValue(1)
param amount int = 25

@description('Name of the persistent guardrails resource group (.lab-env.json guardrails.resourceGroup).')
param guardrailsResourceGroup string = 'lagb-guardrails'

@description('Email address from .lab-env.json budget.contactEmail.')
param contactEmail string = 'student@example.com'

@description('First day of the budget period (first of a month).')
param startDate string = utcNow('yyyy-MM-01')

output guardrailTags object = guardrailTags
output budgetName string = budgetName
output amount int = amount
output guardrailsResourceGroup string = guardrailsResourceGroup
output contactEmail string = contactEmail
output startDate string = startDate

// ---- Your resources go below this line. ----

@description('Action group location (Global).')
param agLocation string = 'global'

module actionGroup 'action-group.bicep' = {
  name: 'lagb-budget-ag'
  scope: resourceGroup(guardrailsResourceGroup)
  params: {
    contactEmail: contactEmail
    location: agLocation
    tags: guardrailTags
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
        contactGroups: [
          actionGroup.outputs.id
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
        contactGroups: [
          actionGroup.outputs.id
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
        contactGroups: [
          actionGroup.outputs.id
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
        contactGroups: [
          actionGroup.outputs.id
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
        contactGroups: [
          actionGroup.outputs.id
        ]
      }
    }
  }
}
