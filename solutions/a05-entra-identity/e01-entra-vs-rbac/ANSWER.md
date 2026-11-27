# a05-e01-entra-vs-rbac

## Scenario 1 Allowed
allowed

## Scenario 1 System
Azure RBAC

## Scenario 1 Reason
Storage Account Contributor at resource group `lagb-a06-lab` includes Microsoft.Storage write at that group. Creating StorageV2 account `lagblabstore01` in that group is an Azure resource-manager action, not a directory action. Learn: <https://learn.microsoft.com/azure/role-based-access-control/built-in-roles>.

## Scenario 2 Allowed
allowed

## Scenario 2 System
Entra directory role

## Scenario 2 Reason
User Administrator is an Entra directory role. It can create and manage cloud users in that tenant, including `lagb-pat@labtenant.onmicrosoft.com`. It does not grant Azure resource-manager actions. Learn: <https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference>.

## Scenario 3 Allowed
allowed

## Scenario 3 System
neither

## Scenario 3 Reason
Contributor at subscription `lagb-personal` is Azure RBAC and does not invite guests. The invite is allowed by Entra's **default** guest-invite settings: Chris is a **member** of the A05 test tenant. Learn: "By default, all users in your organization, including B2B collaboration guest users, can invite external users." Source: <https://learn.microsoft.com/entra/external-id/external-collaboration-settings-configure> (Specify who can invite guests / default).

## Scenario 4 Allowed
denied

## Scenario 4 System
neither

## Scenario 4 Reason
Helpdesk Administrator is an Entra directory role (password reset and similar helpdesk tasks in the directory). Creating resource group `lagb-new` is Azure resource-manager work. An Entra role does not create Azure resource groups. Learn: <https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference>.

## Scenario 5 Allowed
denied

## Scenario 5 System
neither

## Scenario 5 Reason
Owner at storage account `lagbstorlab` is Azure RBAC at that resource. Resetting another cloud user's password is an Entra directory action (User Administrator, Helpdesk Administrator, or similar). Resource Owner does not grant directory password reset. Learn: <https://learn.microsoft.com/azure/role-based-access-control/overview>.

## Scenario 6 Allowed
denied

## Scenario 6 System
neither

## Scenario 6 Reason
Groups Administrator manages Entra groups, not Azure role assignments. Assigning Azure Reader on resource group `lagb-a06-lab` needs an Azure RBAC privileged role at that scope (Owner or User Access Administrator), not an Entra Groups Administrator role. Learn: <https://learn.microsoft.com/azure/role-based-access-control/built-in-roles>.
