# A02: Cost control and lab guardrails

## Advance organizer

You have written Bicep files and understand deployments. This unit teaches cost control: how to deploy a monthly budget with alerts, how to read Azure Advisor recommendations, and how to tag and isolate lab resources so they can be found and cleaned up. This unit contains the course's first live deployment to Azure. You will deploy a budget and action group, then export the deployment. That budget gates every later resource lab: `lab-up` requires a subscription-scope budget whose name matches `.lab-env.json` `budget.name` (default `lagb-monthly`) and whose amount is greater than 0. The gate checks only the name and amount, not alerts or thresholds. Without a matching budget, `lab-up` refuses and exits with code 3. With `-BudgetOverride`, `lab-up` deploys anyway and prints console warnings only (no log file).

You must already know: **A00** (Bicep language and structure) and **A01** (deployments and ARM JSON).

After this unit you can:
- Deploy an Azure budget with actual-cost and forecasted-cost alerts
- Deploy an action group that sends email alerts
- Tag lab resources so `lab-down` and the sweep can find them
- Read Advisor recommendations to find idle or misconfigured resources
- Confirm the active Azure account matches the lab environment

## Foundations

### Why budgets matter

Azure bills by usage. If you create a virtual machine and leave it running, you are charged by the hour. If you create a public IP address and do not delete it, you are charged hourly (Standard IPs bill about $0.005/hr). A budget alerts you when spending reaches thresholds. Without a budget, you discover overages after the fact.

The course budget is set at **$10–$25 per month**. This covers the labs in units A02 through A17. Azure allows at most 5 notifications per budget. The course set is Actual 50/80/100% and Forecasted 80/100%. Actual cost is what you have spent so far. Forecasted cost is what Azure predicts you will spend by the end of the billing period, based on current usage. Forecasted alerts catch runaway costs before they hit the limit.

If you exceed the budget, Azure does not stop your resources. A budget is a monitoring tool, not a quota. The action group sends you an email; you decide whether to clean up resources or raise the budget.

### Budgets and action groups

A **budget** tracks spending and defines alert thresholds. An **action group** defines notification targets (e.g., email addresses). When spending crosses a threshold, the budget sends an alert via the action group. Azure supports budgets at resource-group, subscription, management-group, and billing scopes; the course budget is subscription scope, and the `lab-up` gate only sees the subscription-scope budget named `.lab-env.json` `budget.name`. Action groups are resource-group-scoped. The budget references the action group by resource ID.

### Deploying a budget

A budget is `Microsoft.Consumption/budgets@2024-08-01`, deployed at subscription scope. Here is a neighboring example with one Actual notification and one Forecasted notification:

```bicep
targetScope = 'subscription'

@description('Budget name')
param budgetName string

@description('Budget amount in USD')
param budgetAmount int

@description('Budget start date (first of month)')
param startDate string = utcNow('yyyy-MM-01')

@description('Action group resource ID for alerts')
param actionGroupId string

resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      Actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: []
        contactGroups: [
          actionGroupId
        ]
        thresholdType: 'Actual'
      }
      Forecasted100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: []
        contactGroups: [
          actionGroupId
        ]
        thresholdType: 'Forecasted'
      }
    }
  }
}
```

The budget tracks spending monthly. When actual cost reaches 80% or forecasted cost reaches 100%, Azure sends an alert to the action group. The action group (resource type `Microsoft.Insights/actionGroups@2023-01-01`) is a separate resource that holds email addresses or other notification targets.

**Note on `startDate`:** A redeploy in a later month changes `utcNow('yyyy-MM-01')`. Pass the original start date when redeploying, or leave the budget alone after the first deploy.

### The A02 lab and exporting a subscription-scoped deployment

Exercise e01's `up.ps1` creates the **persistent** guardrails resource group (`.lab-env.json` `guardrails.resourceGroup`, default `lagb-guardrails`), tagged `course=LearnAzureByGrinding`, `unit=a02-cost-and-guardrails`, `exercise=<the A02 exercise id>`, `lifecycle=persistent`, `owner=<owner>` (no `expires` tag), then runs `az deployment sub create` for the subscription-scope budget deployment. The budget gate runs before `up.ps1` for every resource lab outside A02; A02 itself is exempt from that gate (the budget does not exist until e01 deploys it). `lab-down` skips persistent groups unless `-IncludePersistent` is given, and `lab-sweep` lists them as expected without counting toward exit 1.

After deployment, export the subscription-scoped deployment with:

```bash
az deployment sub export \
  --name <deployment-name> \
  > exported.json
```

This parallels A01's `az deployment group export` for resource-group-scoped deployments. The exported ARM JSON can be decompiled to Bicep for version control.

### Lab resource tagging

Every lab resource and resource group carries five tags (exception: the persistent guardrails group has `course`, `unit`, `exercise`, `lifecycle=persistent`, `owner`, and no `expires`):

| Tag | Value format | Example |
|-----|--------------|---------|
| `course` | `LearnAzureByGrinding` (literal) | `LearnAzureByGrinding` |
| `unit` | Unit folder name | `a02-cost-and-guardrails` |
| `exercise` | Full exercise id | `a02-e01-budget-and-action-group` |
| `expires` | UTC timestamp `yyyy-MM-ddTHH:mm:ssZ`, written by `New-LabTags`, default now plus 8 hours (`-ExpiresInHours` flag) | `2026-11-21T20:30:00Z` |
| `owner` | Your username | `student` |

`lab-up` puts these five tags on the resource group it creates. `lab-down` selects **resource groups** by the `course` tag, name prefix, and `unit` tag (plus `exercise` with `-Path`), skips persistent groups unless `-IncludePersistent` is passed, then runs `az group delete`. That removes every resource in the group, regardless of the resource's own tags.

### Azure Advisor

Azure Advisor analyzes your resources and recommends improvements in five categories: Cost, Security, Reliability, Operational Excellence, and Performance. Each recommendation has an impact level (High, Medium, Low), a description, the affected resource, and a remediation action.

Read recommendations in the portal or with `az advisor recommendation list --output table`. Advisor is reactive: it only analyzes existing resources. After a lab, check for idle VMs or unattached disks.

### Account isolation

The lab environment is recorded in `.lab-env.json` at the repository root (`expectedTenantId`, `expectedSubscriptionId`, and `expectedEntraTenantId`). Before a lab, run `az account show` to confirm the active account matches. If not, sign in: `az login --tenant <tenant-id>` and `az account set --subscription <subscription-id>`. The `lab-up` script enforces this to prevent deploying into a work subscription by mistake, and it refuses if the tenant looks corporate.

To check the budget that gates later labs, run:

```bash
az consumption budget list --output table
```

This is the lookup `lab-up` uses to find the subscription-scope budget named `.lab-env.json` `budget.name`.

### What costs money if left running

Resources that cost money when idle:
- Virtual machines: **Stopped (deallocated)** (`az vm deallocate`) stops the compute charge, but disks and public IPs keep billing. **Stopped** (not deallocated) still bills compute. Every lab VM must have auto-shutdown.
- Public IP addresses: Standard IPs bill **hourly** (about $0.005/hr) until the IP resource is deleted.
- Azure Bastion: bills hourly.
- Managed disks: bill by size, even if unattached.
- Recovery Services vaults: the protected-instance meter bills (about $10/month per VM), and soft delete **blocks vault deletion** for 14 days (the soft-delete storage itself is not billed).
- App Service plans: Free tier is free; Basic and above bill even if empty.
- Load balancers: Standard Load Balancers bill hourly once they have rules, whether or not they have a public IP (the IP bills separately).
- Site Recovery and cross-region replication: bill continuously.

Resource groups are free. Tear down every lab immediately after you verify it passes. The `lab-down` script deletes the resource group. If you keep a lab running overnight, check Advisor the next day for unexpected costs.

## Worked example: Reading an Advisor recommendation

You delete a VM, and its disk is left behind unattached. The next day, Advisor shows a Cost recommendation about the unattached disk. The disk is charged by size. Run `lab-down` to delete the resource group, which removes the disk.

**The plausible wrong reading.** You might expect Advisor to alert immediately after you stop the VM. Advisor is not real-time; recommendations appear hours or days later. Budgets are also not real-time: cost data lags, and budget evaluation is periodic (typically daily). Forecasted budget thresholds catch runaway costs earlier than Actual thresholds, but neither alerts immediately. Advisor catches waste you forgot to clean up.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Budget vs quota | A budget is a monitoring tool that sends alerts when spending crosses thresholds. A quota is a hard limit enforced by Azure (e.g., maximum number of cores per region). Budgets do not stop resources; quotas block creation. |
| Actual cost vs Forecasted cost | Actual cost is what you have spent so far in the billing period. Forecasted cost is what Azure predicts you will spend by the end of the period, based on current usage. Forecasted alerts catch runaway costs early. |
| Action group vs alert rule | An alert rule is a condition (e.g., "cost exceeds 50%"). An action group is a set of targets (e.g., "send email to student@example.com"). The budget defines alert rules and references an action group. The action group is reusable: multiple budgets can reference the same action group. |
| Stopped VM vs Stopped (deallocated) VM vs deleted VM | **Stopped** (not deallocated) still bills compute, disks, and public IPs. **Stopped (deallocated)** stops the compute charge but disks and IPs keep billing. **Deleted** leaves its managed OS and data disks, NIC, and public IP in place; they keep billing. What survives a VM delete depends on each resource's `deleteOption` (API default is Detach; portal defaults the OS disk and NIC to Delete). Deleting the lab's resource group (`lab-down`) removes everything. |
| Resource group tags vs resource tags | A resource group can have tags, and resources in that group can have tags. The tags are independent. Setting a tag on the resource group does not set it on the resources inside. The course requires tags on both. |
| Lab-down vs lab-sweep | `lab-down` deletes resource groups (not individual resources). `lab-sweep` is the **student's** tool: it lists every course-tagged group and resource with its expiry and cost risk, plus soft-deleted Key Vaults. It deletes nothing and exits 1 if anything is left (the A02 guardrails group is listed separately as expected and won't fail it). |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Create and manage Azure budgets](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets) — budget setup and alert configuration
- [Action groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups) — action group types and configuration
- [Azure Advisor overview](https://learn.microsoft.com/en-us/azure/advisor/advisor-overview) — what Advisor checks and how to use it
- [Azure Advisor cost recommendations](https://learn.microsoft.com/en-us/azure/advisor/advisor-cost-recommendations) — specific cost recommendations
- [Use tags to organize Azure resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources) — tag syntax and best practices
- [Understand Azure spending](https://learn.microsoft.com/en-us/azure/cost-management-billing/understand/review-individual-bill) — how billing works
- [az consumption budget](https://learn.microsoft.com/en-us/cli/azure/consumption/budget) — CLI commands for budgets (what `lab-up` uses to look up the budget)
- [Microsoft.Consumption/budgets](https://learn.microsoft.com/en-us/azure/templates/microsoft.consumption/budgets) — Bicep/ARM template reference for budgets
- [az advisor](https://learn.microsoft.com/en-us/cli/azure/advisor) — CLI commands for Advisor
- [az account show](https://learn.microsoft.com/en-us/cli/azure/account#az-account-show) — show the active account and subscription

## Check yourself

<details>
<summary>Answers</summary>

1. **A budget has a monthly amount of $20 and an alert at 100% Actual cost. You spend $21. What happens?**  
   Azure sends an alert email (via the action group). The budget does not stop your resources. You receive the alert and decide whether to clean up resources or raise the budget.

2. **A budget has alerts at 50% and 100% of Forecasted cost. On day 10 of a 30-day month, you have spent $5 of a $20 budget. Azure forecasts you will spend $25 by the end of the month. Which alerts fire?**  
   Both the 50% and 100% Forecasted alerts fire. The forecast is $25, which is 125% of the $20 budget. Both 50% ($10 forecasted) and 100% ($20 forecasted) thresholds are crossed.

3. **You deploy a VM inside a lab resource group and forget to add the `course` tag to the VM. You run `lab-down`. What happens to the VM?**  
   The VM is deleted. `lab-down` selects **resource groups** by the `course` tag, then runs `az group delete`. That removes every resource in the group, regardless of the resource's own tags.

4. **You deploy a VM with a public IP and a managed disk. You stop the VM (not deallocate). What costs remain?**  
   Compute, the disk, and the public IP. **Stopped** (not deallocated) still bills compute. Only **Stopped (deallocated)** (`az vm deallocate`) stops the compute charge. Disks and public IPs keep billing either way. To stop all charges, run `lab-down` to delete the resource group (deleting the VM alone leaves disks and IPs in place).

5. **Advisor shows a recommendation in the Cost category with Low impact. Should you act on it immediately?**  
   Not necessarily. Low impact means the cost is small. Prioritize High and Medium recommendations. Low recommendations are worth fixing when convenient, but they are not urgent. If you are over budget, fix High and Medium first.

</details>

## Takeaways

- A budget alerts you when spending crosses thresholds; it does not stop resources.
- Forecasted alerts catch runaway costs early by predicting end-of-month spending from current usage.
- Every lab resource and resource group must have the five course tags (`course`, `unit`, `exercise`, `expires`, `owner`), except the persistent guardrails group has `lifecycle=persistent` and no `expires`.
- Advisor recommends improvements to existing resources; it analyzes periodically, not in real time.
- Stopped (not deallocated) VMs bill compute, disks, and IPs; Stopped (deallocated) VMs bill disks and IPs; deleting a VM leaves disks and IPs that keep billing (what survives depends on `deleteOption`); `lab-down` deletes the resource group and removes everything.
- The first live lab deploys a budget and action group at subscription scope and exports the deployment with `az deployment sub export`.

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
