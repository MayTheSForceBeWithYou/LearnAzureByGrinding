# A02: Cost control and lab guardrails

## Advance organizer

You have written Bicep files and understand deployments. This unit teaches cost control: how to deploy a monthly budget with alerts, how to read Azure Advisor recommendations, and how to tag and isolate lab resources so they can be found and cleaned up. This unit contains the course's first live deployment to Azure. You will deploy a budget and action group, then export the deployment. That budget gates every later lab: the harness refuses to deploy if the budget is missing.

You must already know: **A00** (Bicep language and structure) and **A01** (deployments and ARM JSON).

After this unit you can:
- Deploy an Azure budget with actual-cost and forecasted-cost alerts
- Deploy an action group that sends email alerts
- Tag lab resources so `lab-down` and the sweep can find them
- Read Advisor recommendations to find idle or misconfigured resources
- Confirm the active Azure account matches the lab environment

## Foundations

### Why budgets matter

Azure bills by usage. If you create a virtual machine and leave it running, you are charged by the hour. If you create a public IP address and do not delete it, you are charged daily. A budget alerts you when spending reaches thresholds. Without a budget, you discover overages after the fact.

The course budget is set at **$10–$25 per month**. This covers the labs in units A02 through A17. The alerts fire at **50%, 80%, and 100%** of both **Actual** and **Forecasted** cost. Actual cost is what you have spent so far. Forecasted cost is what Azure predicts you will spend by the end of the billing period, based on current usage. Forecasted alerts catch runaway costs before they hit the limit.

If you exceed the budget, Azure does not stop your resources. A budget is a monitoring tool, not a quota. The action group sends you an email; you decide whether to clean up resources or raise the budget.

### Budgets and action groups

A **budget** tracks spending and defines alert thresholds. An **action group** defines notification targets (e.g., email addresses). When spending crosses a threshold, the budget sends an alert via the action group. Budgets are subscription-scoped or resource-group-scoped. Action groups are resource-group-scoped. The budget references the action group by resource ID.

### Deploying a budget and action group

A budget is `Microsoft.CostManagement/budgets`. An action group is `Microsoft.Insights/actionGroups`. Here is a subscription-scoped deployment that creates both:

```bicep
targetScope = 'subscription'

@description('Resource group for the action group')
param actionGroupRg string

@description('Action group name')
param actionGroupName string

@description('Email address for alerts')
param emailAddress string

@description('Budget name')
param budgetName string

@description('Budget amount in USD')
param budgetAmount int = 25

@description('Location for the action group')
param location string = 'eastus'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: actionGroupRg
}

module actionGroup 'actiongroup.bicep' = {
  name: 'actionGroupDeployment'
  scope: rg
  params: {
    actionGroupName: actionGroupName
    emailAddress: emailAddress
    location: location
  }
}

resource budget 'Microsoft.CostManagement/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '2026-11-01'
      endDate: '2027-11-01'
    }
    notifications: {
      Actual50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: []
        contactGroups: [
          actionGroup.outputs.actionGroupId
        ]
        thresholdType: 'Actual'
      }
      Actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: []
        contactGroups: [
          actionGroup.outputs.actionGroupId
        ]
        thresholdType: 'Actual'
      }
      Actual100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: []
        contactGroups: [
          actionGroup.outputs.actionGroupId
        ]
        thresholdType: 'Actual'
      }
      Forecasted50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: []
        contactGroups: [
          actionGroup.outputs.actionGroupId
        ]
        thresholdType: 'Forecasted'
      }
      Forecasted80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: []
        contactGroups: [
          actionGroup.outputs.actionGroupId
        ]
        thresholdType: 'Forecasted'
      }
      Forecasted100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: []
        contactGroups: [
          actionGroup.outputs.actionGroupId
        ]
        thresholdType: 'Forecasted'
      }
    }
  }
}
```

The action group module:

```bicep
@description('Action group name')
param actionGroupName string

@description('Email address')
param emailAddress string

@description('Location')
param location string

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  properties: {
    groupShortName: substring(actionGroupName, 0, min(length(actionGroupName), 12))
    enabled: true
    emailReceivers: [
      {
        name: 'EmailAlert'
        emailAddress: emailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
```

The budget is subscription-scoped. The action group is resource-group-scoped. The budget references the action group by its resource ID, returned as an output from the module.

### Lab resource tagging

Every lab resource carries five tags: `course` (`LearnAzureByGrinding`), `unit` (folder name), `exercise` (full id), `expires` (ISO date shortly after the lab), and `owner` (your username). The `lab-down` script selects by the `course` tag. The `expires` date should be a few days after the lab; redeploy with a new date if you need resources longer.

### Azure Advisor

Azure Advisor analyzes your resources and recommends improvements in five categories: Cost, Security, Reliability, Operational Excellence, and Performance. Each recommendation has an impact level (High, Medium, Low), a description, the affected resource, and a remediation action.

Read recommendations in the portal or with `az advisor recommendation list --output table`. Advisor is reactive: it only analyzes existing resources. After a lab, check for idle VMs or unattached disks.

### Account isolation

The lab environment is recorded in `.lab-env.json` at the repository root (tenant ID and subscription ID). Before a lab, run `az account show` to confirm the active account matches. If not, sign in: `az login --tenant <tenant-id>` and `az account set --subscription <subscription-id>`. The `lab-up` script enforces this to prevent deploying into a work subscription by mistake.

### What costs money if left running

Resources that cost money when idle: virtual machines (even stopped, the disks remain), public IP addresses (charged daily), Azure Bastion (charged hourly), managed disks (charged by size), and Recovery Services vaults (soft delete retains items for 14 days). Resource groups are free.

Tear down every lab immediately after you verify it passes. The `lab-down` script deletes the resource group. If you keep a lab running overnight, check Advisor the next day for unexpected costs.

## Worked example: Reading an Advisor recommendation

You stop a VM but do not delete it. The next day, Advisor shows a Medium-impact Cost recommendation: "Virtual machine is stopped but the disk remains allocated. The disk incurs charges even when the VM is not running." The disk is charged by size, whether or not the VM is running. Run `lab-down` to delete the resource group, which deletes both the VM and the disk.

**The plausible wrong reading.** You might expect Advisor to alert immediately after you stop the VM. Advisor is not real-time; recommendations appear hours or days later. For real-time alerts, use Forecasted budget thresholds. Advisor catches waste you forgot to clean up.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Budget vs quota | A budget is a monitoring tool that sends alerts when spending crosses thresholds. A quota is a hard limit enforced by Azure (e.g., maximum number of cores per region). Budgets do not stop resources; quotas do. |
| Actual cost vs Forecasted cost | Actual cost is what you have spent so far in the billing period. Forecasted cost is what Azure predicts you will spend by the end of the period, based on current usage. Forecasted alerts catch runaway costs early. |
| Action group vs alert rule | An alert rule is a condition (e.g., "cost exceeds 50%"). An action group is a set of targets (e.g., "send email to n8@example.com"). The budget defines alert rules and references an action group. The action group is reusable: multiple budgets can reference the same action group. |
| Stopped VM vs deleted VM | A stopped VM still incurs costs (the disks, the public IP if allocated). A deleted VM incurs no costs. To stop charges, delete the VM, not just stop it. |
| Resource group tags vs resource tags | A resource group can have tags, and resources in that group can have tags. The tags are independent. Setting a tag on the resource group does not set it on the resources inside. The course requires tags on both. |
| Lab-down vs lab-sweep | `lab-down` is a script you run manually to delete the resource group(s) a lab created. `lab-sweep` is a script the course owner runs periodically to find expired resources (by `expires` tag) and report them. You use `lab-down`; the owner uses `lab-sweep`. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Create and manage Azure budgets](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets) — budget setup and alert configuration
- [Action groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups) — action group types and configuration
- [Azure Advisor overview](https://learn.microsoft.com/en-us/azure/advisor/advisor-overview) — what Advisor checks and how to use it
- [Azure Advisor cost recommendations](https://learn.microsoft.com/en-us/azure/advisor/advisor-cost-recommendations) — specific cost recommendations
- [Use tags to organize Azure resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources) — tag syntax and best practices
- [Understand Azure spending](https://learn.microsoft.com/en-us/azure/cost-management-billing/understand/review-individual-bill) — how billing works
- [az costmanagement](https://learn.microsoft.com/en-us/cli/azure/costmanagement) — CLI commands for cost management (note: budgets are not in `az costmanagement`; they are ARM resources deployed via `az deployment`)
- [az advisor](https://learn.microsoft.com/en-us/cli/azure/advisor) — CLI commands for Advisor
- [az account show](https://learn.microsoft.com/en-us/cli/azure/account#az-account-show) — show the active account and subscription

## Check yourself

<details>
<summary>Answers</summary>

1. **A budget has a monthly amount of $20 and an alert at 100% Actual cost. You spend $21. What happens?**  
   Azure sends an alert email (via the action group). The budget does not stop your resources. You receive the alert and decide whether to clean up resources or raise the budget.

2. **A budget has alerts at 50% and 100% of Forecasted cost. On day 10 of a 30-day month, you have spent $5 of a $20 budget. Azure forecasts you will spend $25 by the end of the month. Which alerts fire?**  
   Both the 50% and 100% Forecasted alerts fire. The forecast is $25, which is 125% of the $20 budget. Both 50% ($10 forecasted) and 100% ($20 forecasted) thresholds are crossed.

3. **You deploy a VM and forget to add the `course` tag. You run `lab-down`. What happens to the VM?**  
   The VM is not deleted. `lab-down` selects resources by the `course` tag. If the tag is missing, `lab-down` does not find the resource. You must delete it manually or add the tag and run `lab-down` again.

4. **You deploy a VM with a public IP and a managed disk. You stop the VM (not delete). What costs remain?**  
   The disk and the public IP. Both are charged even when the VM is stopped. To stop charges, delete the VM (which deletes the disk if the delete option is set to `Delete`) and delete the public IP.

5. **Advisor shows a recommendation in the Cost category with Low impact. Should you act on it immediately?**  
   Not necessarily. Low impact means the cost is small. Prioritize High and Medium recommendations. Low recommendations are worth fixing when convenient, but they are not urgent. If you are over budget, fix High and Medium first.

</details>

## Takeaways

- A budget alerts you when spending crosses thresholds; it does not stop resources.
- Forecasted alerts catch runaway costs early by predicting end-of-month spending from current usage.
- Every lab resource and resource group must have the five course tags (`course`, `unit`, `exercise`, `expires`, `owner`).
- Advisor recommends improvements to existing resources; it does not monitor costs in real time.
- Stopped VMs still incur costs (disks, public IPs); deleted VMs do not.
- The first live lab deploys a budget and action group at subscription or resource-group scope and exports the deployment.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-budget-and-action-group | WRITE, LAB | M | Write the course budget and action group, then deploy and export it |
| 2 | e02-advisor-recommendations | CLI | S | Read Advisor recommendations from a fixture |
| 3 | e03-missing-forecast-alerts | BUG | S | Find and fix a budget missing Forecasted alerts |
| 4 | e04-idle-resource-cost | PREDICT | S | Predict the cost of leaving lab resources running |
| 5 | e05-account-isolation | CLI | S | Confirm the active account matches the lab environment |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-course-tags | Write the five course tags on a resource |
| 2 | r02-budget-alert-thresholds | Write budget notifications with Actual and Forecasted thresholds |
