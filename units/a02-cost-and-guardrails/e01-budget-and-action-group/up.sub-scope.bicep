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
