# a05-e01-entra-vs-rbac `[EXPLAIN]` (S)

## Goal

Decide, for each scenario below, whether the named action is **allowed**, and which system grants or denies it: an **Entra directory role** or **Azure RBAC**. Write `ANSWER.md`. Do not change `main.bicep`.

Entra directory roles control the directory (users, groups, guests, licences). Azure RBAC controls Azure resource-manager actions at a subscription, resource group, or resource. They are not interchangeable. Confirm role permissions on Learn before you answer:

- Entra built-in roles: <https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference>
- Azure built-in roles: <https://learn.microsoft.com/azure/role-based-access-control/built-in-roles>
- Azure RBAC overview: <https://learn.microsoft.com/azure/role-based-access-control/overview>

## Scenarios

Each row is one person, one role held at one scope, and one action they attempt **right now**. No other roles, PIM, or group nesting. Do not use the Global Administrator "elevate access" path, and do not reason from "the role was assigned to a group" — those are the lesson's worked examples, not these cases.

1. **Alex** holds **Storage Account Contributor** at resource group `lagb-a06-lab`. Action: create a StorageV2 account named `lagblabstore01` in that resource group.
2. **Blair** holds **User Administrator** (Entra directory role) in the A05 test tenant. Action: create a cloud-only user `lagb-pat@labtenant.onmicrosoft.com` in that tenant.
3. **Chris** holds **Contributor** at subscription `lagb-personal`. Action: invite `guest@example.com` as a B2B guest into the Entra directory.
4. **Dana** holds **Helpdesk Administrator** (Entra directory role) in the A05 test tenant. Action: create resource group `lagb-new` in the lab Azure subscription.
5. **Evan** holds **Owner** at storage account `lagbstorlab` (the resource, not the subscription). Action: reset the password of another cloud user in the A05 test tenant.
6. **Fay** holds **Groups Administrator** (Entra directory role) in the A05 test tenant. Action: assign the Azure **Reader** role on resource group `lagb-a06-lab` to Alex.

## Constraints

- `ANSWER.md` uses the required headings exactly, with text under each.
- Under **Allowed**, write `allowed` or `denied`.
- Under **System**, name `Entra directory role`, `Azure RBAC`, or `neither` (the action is not granted by the role they hold).
- Under **Reason**, cite the role and scope: what that role can do, and why it does or does not cover this action.
- Do not invent portal or CLI output. Do not change `main.bicep`.

Required `ANSWER.md` headings (exact lines):

- `## Scenario 1 Allowed`
- `## Scenario 1 System`
- `## Scenario 1 Reason`
- `## Scenario 2 Allowed`
- `## Scenario 2 System`
- `## Scenario 2 Reason`
- `## Scenario 3 Allowed`
- `## Scenario 3 System`
- `## Scenario 3 Reason`
- `## Scenario 4 Allowed`
- `## Scenario 4 System`
- `## Scenario 4 Reason`
- `## Scenario 5 Allowed`
- `## Scenario 5 System`
- `## Scenario 5 Reason`
- `## Scenario 6 Allowed`
- `## Scenario 6 System`
- `## Scenario 6 Reason`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
