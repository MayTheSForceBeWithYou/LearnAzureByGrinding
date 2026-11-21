// Reference template for a subscription-scope lab (copied next to up.ps1 by the author; see
// lib/templates/up.sub-scope.ps1 and docs/AUTHORING-INFRA.md "Subscription-scope up.ps1").
// Deploys the A02 action group into the persistent guardrails group (which up.ps1 has already
// created or reused) and the subscription budget the lab guard looks for.
// The budget is Microsoft.Consumption/budgets at subscription scope: the same resource
// `az consumption budget list` returns, which is what lab-up's budget gate reads.
targetScope = 'subscription'

@description('Budget name. Must equal .lab-env.json budget.name (default lagb-monthly) or the lab guard will not find it.')
param budgetName string = 'lagb-monthly'

@description('Monthly budget amount in the billing currency. Must be > 0.')
@minValue(1)
param amount int = 25

@description('Name of the existing persistent guardrails resource group (.lab-env.json guardrails.resourceGroup).')
param guardrailsResourceGroup string = 'lagb-guardrails'

@description('Email address that receives budget alerts.')
param contactEmail string

@description('Tags for the action group (guardrail tags: course, unit=a02-cost-and-guardrails, exercise, lifecycle=persistent, owner; no expires).')
param guardrailTags object

@description('First day of the budget period. Must be the first of a month.')
param startDate string = utcNow('yyyy-MM-01')

resource guardrails 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: guardrailsResourceGroup
}

module actionGroup 'up.sub-scope.action-group.bicep' = {
  name: 'lagb-guardrails-action-group'
  scope: guardrails
  params: {
    name: '${budgetName}-ag'
    shortName: 'lagbbudget'
    contactEmail: contactEmail
    tags: guardrailTags
  }
}

// A budget allows at most five notifications: Actual at 50/80/100 % and Forecasted at 80/100 %.
var alerts = [
  { key: 'actual50', threshold: 50, thresholdType: 'Actual' }
  { key: 'actual80', threshold: 80, thresholdType: 'Actual' }
  { key: 'actual100', threshold: 100, thresholdType: 'Actual' }
  { key: 'forecasted80', threshold: 80, thresholdType: 'Forecasted' }
  { key: 'forecasted100', threshold: 100, thresholdType: 'Forecasted' }
]

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: toObject(alerts, a => a.key, a => {
      enabled: true
      operator: 'GreaterThanOrEqualTo'
      threshold: a.threshold
      thresholdType: a.thresholdType
      contactEmails: [
        contactEmail
      ]
      contactGroups: [
        actionGroup.outputs.actionGroupId
      ]
    })
  }
}

output budgetId string = budget.id
output actionGroupId string = actionGroup.outputs.actionGroupId
