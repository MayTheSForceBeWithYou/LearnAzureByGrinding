# A05: Microsoft Entra users, groups, and directory access

## Advance organizer

You have assigned Azure RBAC roles at resource and subscription scope and enforced Policy at subscription and resource-group scope. This unit teaches Microsoft Entra identity management: creating cloud users and groups, inviting external users, managing user properties and licenses, and understanding the boundary between Entra directory roles and Azure RBAC. After this unit you can create users and groups in a test tenant, explain what SSPR and Conditional Access require, and describe why an Entra directory administrator does not automatically have access to Azure resources.

You must already know: **A00** (Bicep language), **A01** (deployments and ARM), **A03** (resource organization), and **A04** (Azure Policy and RBAC).

After this unit you can:
- Create cloud users and security groups, and manage group membership
- Invite external guest users (B2B collaboration)
- Explain the usage location requirement for license assignment
- Distinguish Entra directory roles from Azure RBAC roles
- Describe what SSPR, Conditional Access, PIM, and dynamic groups require (Free, P1, or P2)
- Switch directories cleanly in both the portal and the CLI

## Foundations

### Test-tenant rule

**All A05 hands-on work uses a separate disposable Microsoft Entra test tenant**, never your work or personal Default Directory. The lab guard refuses to run unless the active tenant matches `.lab-env.json`'s `expectedEntraTenantId`. This isolation protects production identities. If you have already deleted your test tenant, A05 and A17 Entra exercises are `[EXPLAIN]` only, or use a Microsoft 365 Developer Program tenant (which expires after 90 days of inactivity). Learn how to create a test tenant at <https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant>.

### Switching directories

You switch directories in the portal and the CLI every time you move between resource labs (A00–A04, A06–A16) and Entra work (A05, A17 Entra review).

**Portal**: Click the Settings (gear) icon, then **Directories + subscriptions**. Select the directory you need. For resource labs, that is your personal Default Directory. For A05 and A17 Entra exercises, that is the test tenant.

**CLI**: For resource labs, `az login` without `--tenant` defaults to your personal subscription's tenant, or you explicitly pass `--tenant <personal-tenant-id>`. For A05 Graph and directory work, `az login --tenant <test-tenant-id>`, then confirm `az account show` reports `tenantId` matching your test tenant. Any A05 directory script, and `lab-up.ps1` when the unit is A05, must also match `.lab-env.json`'s `expectedEntraTenantId`.

Resource-deployment scripts (A00–A04, A06–A16, and A17 non-Entra) must target `expectedSubscriptionId` and must not target the A05 directory, because the A05 test tenant typically has no subscription.

### Entra ID Free, P1, and P2

**Works on Entra ID Free** (the default for a new test tenant):
- Create and manage cloud users and security groups (assigned membership)
- Invite external guest users
- Azure RBAC role assignments (this is Azure resource access, taught in A04, not an Entra P1 feature)
- Self-service password *change* (the user knows their current password and changes it)

**Needs Entra ID P1** (or a Microsoft 365 plan that includes P1):
- Dynamic groups (membership rules based on user or device attributes)
- Conditional Access policies
- Self-service password *reset* (password recovery when the user does not know their current password) and group-based SSPR. See <https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-licensing>.

**Needs Entra ID P2**:
- Privileged Identity Management (PIM)
- Entra ID Protection and risk-based Conditional Access

A05 teaches Free-tier tasks as the default path. P1 and P2 tasks are marked clearly as optional or `[EXPLAIN]`. Microsoft offers a 30-day P1/P2 trial (no credit card required as of 2026). After 30 days, P1/P2 features stop working, but your Free-tier users and groups remain. Start the trial only in the **test tenant**, never in a work tenant. See <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id>.

### Microsoft Entra ID and your Azure subscription

**Microsoft Entra ID** (formerly Azure Active Directory) is Microsoft's cloud identity and access management service. Every Azure subscription trusts an Entra tenant for authentication. That tenant holds **users**, **groups**, **service principals** (application identities), and **directory role assignments**.

Your personal Microsoft account (MSA) has a **Default Directory** Entra tenant that Azure automatically creates. That tenant typically holds only your own user object, and you are a Global Administrator. When you create cloud users in the portal or CLI, you create them in the Entra tenant you are currently signed in to.

A **work or school tenant** is an organization's Entra directory (for example, `contoso.onmicrosoft.com`). The course uses a separate **test tenant** for A05 to avoid modifying production or personal identities.

### Users

A **user** in Entra ID is an identity that can sign in. Users have a **user principal name** (UPN, for example `alice@contoso.onmicrosoft.com`), an **object ID** (a GUID), and properties such as display name, mail, and usage location. Cloud users authenticate to Entra ID with their UPN and password. Synchronized users (synced from on-premises Active Directory via Microsoft Entra Connect) authenticate on-premises, and Entra ID trusts the synchronization.

You create cloud users in the portal (Entra ID → Users → New user → Create new user) or via the Azure CLI. Each user needs a UPN (which must be unique in the tenant), a display name, and a password (auto-generated or specified). See the [az ad user](https://learn.microsoft.com/cli/azure/ad/user) reference for CLI operations.

User properties you can set include:
- Display name, given name, surname
- Job title, department, company name, manager
- Contact information (email, mobile phone, office phone, street address)

### Groups

A **security group** contains users, devices, other groups, or service principals. You assign Azure RBAC roles and Entra directory roles to groups, and all members inherit the assignment. Security groups are created with **assigned membership** (you manually add each member) or **dynamic membership** (Entra ID evaluates a rule based on user or device attributes and automatically adds or removes members when those attributes change). Dynamic membership requires Entra ID P1.

You create security groups in the portal (Entra ID → Groups → New group) or via the Azure CLI. Each group needs a display name. See the [az ad group](https://learn.microsoft.com/cli/azure/ad/group) reference for CLI operations.

Nested groups (a group inside another group) are supported for security groups: you can add a security group as a member of another security group. Nested groups simplify RBAC and Conditional Access scope, but they do not inherit access to shared resources and applications assigned to the parent group.

**Microsoft 365 groups** (formerly Office 365 groups) have an email address and are used for collaboration (Teams, SharePoint, Outlook). This course focuses on security groups.

### External (guest) users

**External users** (also called guest users or B2B collaboration users) are identities from outside your tenant who need access to your resources. You invite an external user by sending an invitation to their email address. The guest redeems the invitation, signs in with their own credentials (from their own Entra tenant, Microsoft account, Google, or another identity provider), and appears in your directory as a user object. The portal and CLI distinguish guests from member users.

You invite guests in the portal (Entra ID → Users → New user → Invite external user) or via Microsoft Graph API (`POST /invitations`). The guest receives an email invitation. External users are common when you collaborate with business partners, contractors, or vendors who need access to your Azure resources or applications but do not have an account in your tenant.

Guest users have restricted permissions by default: they cannot enumerate users or groups in your directory unless you grant them additional rights. See <https://learn.microsoft.com/en-us/entra/external-id/what-is-b2b>.

### Licenses and usage location

Some Entra ID features and Microsoft 365 services require a license assigned to each user. License assignment has prerequisites, including setting the user's **usage location** property to a valid two-letter country code (ISO 3166-1 alpha-2, for example `US`, `GB`, `DE`) when the license includes location-restricted services. The portal and Microsoft Graph API support both usage location configuration and license assignment. See <https://learn.microsoft.com/entra/fundamentals/licensing> and <https://learn.microsoft.com/graph/api/user-assignlicense>.

### Entra directory roles versus Azure RBAC roles

**Microsoft Entra directory roles** (such as Global Administrator, User Administrator, Groups Administrator) grant permissions within the Entra tenant: creating users and groups, resetting passwords, managing directory settings. These roles do **not** grant access to Azure resources (subscriptions, resource groups, storage accounts). Directory roles are assigned in the Entra ID portal (Roles and administrators) or via `az role assignment create` with a directory-role definition ID.

**Azure RBAC roles** (such as Owner, Contributor, Reader) grant permissions to Azure resources within a subscription, resource group, or resource scope. RBAC role assignments are created with `az role assignment create` or in Bicep as `Microsoft.Authorization/roleAssignments` (covered in A04). An Entra user with no Azure RBAC assignments cannot see or manage Azure resources, even if they are a Global Administrator.

A Global Administrator in Entra ID can **elevate their access** to gain User Access Administrator at the Azure `/` (root) scope. After elevation, they have RBAC rights across all subscriptions in the tenant. This elevation is a manual step in the portal (Entra ID → Properties → Access management for Azure resources → Yes, then save) or via the REST API. Elevation does not happen automatically. See <https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin>.

### Self-service password reset (SSPR)

**Self-service password reset** (SSPR) allows users to reset their own password when they forget it, without contacting the helpdesk. SSPR requires users to register authentication methods (email, phone, security questions) and verify their identity before resetting the password.

**Password change** (the user knows their current password and wants to change it) works on Entra ID Free. **Password reset** (the user does not know their current password and needs to recover the account) requires Entra ID P1. The official licensing page is <https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-licensing>. Cloud-only users on Free can change their password; they cannot reset it. SSPR with on-premises writeback (the new password is written back to on-premises Active Directory) requires Entra ID P1 or Microsoft 365 Business Premium.

You configure SSPR in the portal (Entra ID → Password reset). Enabling SSPR for all users, or for selected groups, requires P1. The A05 lesson teaches SSPR as an `[EXPLAIN]` or trial-based optional task.

### Conditional Access

**Conditional Access** is Entra ID's policy engine for enforcing access controls: "if this user signs in from this location or device, require MFA" or "block access from untrusted locations." Conditional Access requires Entra ID P1. Policies are configured in the portal (Entra ID → Security → Conditional Access). A common policy is "require multi-factor authentication for all users when signing in from outside the corporate network."

A05 teaches Conditional Access as an `[EXPLAIN]` or trial-based optional task. It is not part of the Free-tier default path.

### Privileged Identity Management (PIM)

**Privileged Identity Management** (PIM) provides just-in-time access to Entra directory roles and Azure RBAC roles. Instead of granting permanent Owner or Global Administrator, you grant an **eligible** assignment. The user activates the role when needed (for a limited time, such as 8 hours), and PIM logs every activation. PIM requires Entra ID P2. See <https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure>.

A05 teaches PIM as an `[EXPLAIN]` or trial-based optional task.

### Dynamic groups

A **dynamic group** has a membership rule that queries user or device attributes. Entra ID evaluates the rule and automatically adds or removes members when their attributes change. Dynamic groups require Entra ID P1. You create a dynamic group in the portal (Entra ID → Groups → New group → Membership type: Dynamic User or Dynamic Device → Add dynamic query). The rule syntax is documented at <https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership>.

A05 teaches dynamic groups as a `[PREDICT]` exercise (given a fixture of users and a rule, predict the membership) rather than a hands-on creation task, because P1 is required.

## Worked example: Entra Global Administrator who cannot access a subscription

You are a Global Administrator in your personal Entra tenant. You create a new Pay-As-You-Go subscription. When you open the Azure portal and navigate to the subscription, you see it listed, but when you try to view resource groups or create resources, you receive an `AuthorizationFailed` error. The portal shows "You don't have access" on the resource groups blade.

This happens because Entra directory roles (such as Global Administrator) do not grant Azure RBAC permissions automatically. Your Global Administrator role gives you full control over the Entra tenant (users, groups, directory settings), but it does not give you access to Azure resources (subscriptions, resource groups, storage accounts). To manage Azure resources, you need an Azure RBAC role assignment, such as Owner or Contributor, at subscription scope.

**To fix this**: elevate your access in the portal (Entra ID → Properties → Access management for Azure resources → toggle to Yes, then save). This grants you the User Access Administrator role at the Azure `/` (root) scope, which applies to all subscriptions in the tenant. After elevation, you can assign yourself Owner or Contributor at subscription scope, then turn off the elevation toggle (it is a temporary mechanism). Now you have both Global Administrator in Entra ID and Owner in Azure.

**The plausible wrong reading.** You might expect that Global Administrator automatically grants full access to everything in Azure, including subscriptions and resources. That is not true. Entra directory roles and Azure RBAC roles are separate systems. A Global Administrator who has no Azure RBAC assignments cannot create or manage Azure resources. Elevation is a manual step that bridges the two systems, and it must be explicitly enabled.

## Worked example: Assign Azure RBAC role to a group

You have a security group `Engineering` in your Entra tenant. You want all members of `Engineering` to have Contributor access to a resource group `dev-rg`. Instead of assigning Contributor to each user individually, you assign it to the group once, and all current and future group members inherit the access.

Here is the subscription-scoped module that assigns Contributor at resource-group scope to a group, using `--assignee-principal-type Group`:

```bicep
targetScope = 'subscription'

param rgName string
param groupObjectId string

module groupContributorAssignment 'group-rbac.bicep' = {
  scope: resourceGroup(rgName)
  name: 'group-contributor-deployment'
  params: {
    groupObjectId: groupObjectId
  }
}
```

The module file `group-rbac.bicep`:

```bicep
targetScope = 'resourceGroup'

param groupObjectId string

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, groupObjectId, contributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: groupObjectId
    principalType: 'Group'
  }
}
```

Deploy this with `az deployment sub create --location eastus --template-file main.bicep --parameters rgName=dev-rg groupObjectId=<group-object-id>`. After deployment, all members of the `Engineering` group have Contributor access to `dev-rg`. Adding a new user to the group grants them access automatically; removing them revokes access automatically. Setting `principalType: 'Group'` avoids deployment delays caused by Azure's propagation checks for principal existence.

**The plausible wrong reading.** You might expect that an Azure RBAC role assignment to a group is an Entra ID P1 feature. That is not true. Azure RBAC role assignments to groups work on Entra ID Free. The P1 feature is **dynamic groups** (groups whose membership is determined by an attribute-based rule), not RBAC assignments to groups. You can assign RBAC roles to assigned-membership groups (manually managed) on Free.

## Distinctions worth keeping straight

| Confusion | What separates them |
|-----------|---------------------|
| Entra directory roles vs Azure RBAC roles | Entra directory roles (Global Administrator, User Administrator) grant permissions in the Entra tenant: managing users, groups, directory settings. Azure RBAC roles (Owner, Contributor, Reader) grant permissions to Azure resources: subscriptions, resource groups, storage accounts. A Global Administrator with no Azure RBAC assignments cannot create or manage Azure resources. Elevation (User Access Administrator at `/`) bridges the two. |
| Entra ID Free vs P1 vs P2 | Free: cloud users, assigned groups, guest invitations, Azure RBAC assignments. P1 adds: dynamic groups, Conditional Access, SSPR. P2 adds: PIM, Entra ID Protection. See the feature licensing table for details. |
| Conditional Access vs MFA | Multi-factor authentication (MFA) is an authentication method: the user proves their identity with something they know (password) and something they have (phone, app, hardware token). Conditional Access is a policy engine that enforces MFA (and other controls, such as device compliance or location restrictions) based on sign-in conditions. Conditional Access requires P1; per-user MFA is available on Free but is less flexible. |
| Elevate access | A manual action in the portal or via REST API that grants a Global Administrator the User Access Administrator role at the Azure `/` (root) scope. After elevation, the Global Administrator can assign Azure RBAC roles at subscription and resource-group scope. Elevation does not happen automatically. |
| Nested groups | A security group can be a member of another security group. Nested groups simplify RBAC and Conditional Access scope, but they do not inherit access to shared resources and applications assigned to the parent group. Azure RBAC role assignments to a group apply to all members, including users in nested groups. |

## Official docs

These are reference, not the reading. The lesson is the reading; the links are where you go to confirm or go deeper.

- [Create a new tenant in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant)
- [How to create, invite, and delete users](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-create-delete-users)
- [How to manage groups and group membership](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-manage-groups)
- [B2B collaboration overview](https://learn.microsoft.com/en-us/entra/external-id/what-is-b2b)
- [Dynamic membership rules for groups](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership)
- [Self-service password reset licensing](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-licensing)
- [What is Conditional Access?](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)
- [What is Privileged Identity Management?](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure)
- [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin)
- [Microsoft Entra built-in roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
- [Assign Microsoft Entra roles to users](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/manage-roles-portal)
- [az ad user](https://learn.microsoft.com/en-us/cli/azure/ad/user)
- [az ad group](https://learn.microsoft.com/en-us/cli/azure/ad/group)
- [Microsoft Graph API users resource](https://learn.microsoft.com/en-us/graph/api/resources/user)

## Check yourself

1. **You are a Global Administrator in your personal Entra tenant. You create a new subscription. You try to create a resource group, and the portal shows "AuthorizationFailed." What must you do?**
2. **You want to block legacy authentication for all users except the break-glass admin accounts and the service principals used by legacy LOB apps. Which Entra ID feature do you need?**
3. **You have a security group with 10 members. You assign the Contributor role at resource-group scope to the group. How many Contributor role assignments exist in that resource group?**
4. **You enable self-service password reset for all users in your test tenant. The tenant is on Entra ID Free. What happens when a user who forgot their password tries to reset it?**
5. **A user is flagged for risky sign-in behavior (impossible travel, anonymous IP). You want Entra ID to automatically require MFA or block access based on the risk level. Which licensing tier do you need?**

<details>
<summary>Answers</summary>

1. Elevate your access in the portal (Entra ID → Properties → Access management for Azure resources → toggle to Yes). This grants you the User Access Administrator role at the Azure `/` (root) scope. After elevation, assign yourself Owner or Contributor at subscription scope. Global Administrator in Entra ID does not automatically grant Azure RBAC permissions.
2. Conditional Access, which requires Entra ID P1. Security defaults (free on every tenant, <https://learn.microsoft.com/entra/fundamentals/security-defaults>) block legacy authentication for all users at no extra cost, but security defaults are all-or-nothing. When you need exceptions (break-glass accounts, service principals, per-app targeting), you need a Conditional Access policy. Conditional Access policies support scoped targeting, exclusions, and conditions. See <https://learn.microsoft.com/entra/identity/conditional-access/overview> and <https://learn.microsoft.com/entra/identity/conditional-access/block-legacy-authentication>.
3. One. Azure RBAC role assignments are recorded once per principal (the group's object ID), not once per member. All members of the group inherit Contributor access to the resource group. Adding or removing users from the group changes their effective permissions, but the number of role assignments stays the same.
4. The portal or CLI shows an error or the SSPR experience is unavailable. Self-service password *reset* (the user does not know their current password) requires Entra ID P1. Password *change* (the user knows their current password) works on Free. If you want SSPR, start a P1 trial in the test tenant or use an `[EXPLAIN]` path.
5. Entra ID P2. Risk-based Conditional Access is an Entra ID Protection feature, which requires P2. Identity Protection detects sign-in and user risks (impossible travel, anonymous IP, leaked credentials, etc.) and can trigger automatic responses through Conditional Access policies. P1 includes Conditional Access but not risk detection. See <https://learn.microsoft.com/entra/id-protection/overview-identity-protection>.

</details>

## Takeaways

- All A05 hands-on work uses a separate disposable test tenant, never your work or personal Default Directory. The lab guard refuses to run unless the active tenant matches `.lab-env.json`'s `expectedEntraTenantId`.
- Switch directories cleanly in the portal (Settings → Directories + subscriptions) and in the CLI (`az login --tenant <id>`, then confirm `az account show` reports the correct `tenantId`).
- Entra ID Free includes: cloud users, assigned-membership security groups, guest invitations, and password change. P1 adds: dynamic groups, Conditional Access, and SSPR password reset. P2 adds: PIM and Entra ID Protection.
- Usage location (a two-letter country code) is required before you can assign a license that includes location-restricted services. Without it, license assignment fails.
- Entra directory roles (Global Administrator, User Administrator) grant permissions in the Entra tenant. Azure RBAC roles (Owner, Contributor, Reader) grant permissions to Azure resources. A Global Administrator with no Azure RBAC assignments cannot create or manage Azure resources. Elevate access (User Access Administrator at `/`) bridges the two.
- Azure RBAC role assignments to security groups work on Entra ID Free. The P1 feature is dynamic groups (rule-based membership), not RBAC assignments to groups.
- Guest users (external users, B2B collaboration) are invited by email, sign in with their own credentials, and appear in your directory as user objects. The portal and CLI distinguish guests from member users.

### Feature licensing summary

Before working with P1 and P2 features, understand what each tier provides. Each row cites <https://learn.microsoft.com/entra/fundamentals/licensing> plus deeper feature-specific pages where available:

| Feature | Entra ID Free | Entra ID P1 | Entra ID P2 | Source |
|---------|---------------|-------------|-------------|--------|
| Cloud users and assigned-membership groups | ✓ | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing) |
| Guest user invitations (B2B) | ✓ | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing), [B2B](https://learn.microsoft.com/entra/external-id/what-is-b2b) |
| Self-service password *change* (user knows current password) | ✓ | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing) |
| Azure RBAC role assignments | ✓ | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing) (not an Entra P1 feature) |
| Self-service password *reset* (password recovery) | | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing), [SSPR licensing](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing) |
| Dynamic groups (rule-based membership) | | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing), [dynamic groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership) |
| Conditional Access policies | | ✓ | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing), [CA overview](https://learn.microsoft.com/entra/identity/conditional-access/overview) |
| Privileged Identity Management (PIM) | | | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing), [PIM](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-configure) |
| Entra ID Protection (risk-based Conditional Access) | | | ✓ | [licensing](https://learn.microsoft.com/entra/fundamentals/licensing) |

**30-day trial**: Microsoft offers a free 30-day trial of Entra ID P1 and P2 (no credit card required as of 2026). After 30 days, P1/P2 features stop working, but Free-tier users and groups remain. Start the trial only in your test tenant, never in a work tenant. See <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id>.

## Exercises

| # | Folder | Tag | Size | What |
|---|--------|-----|------|------|
| 1 | e01-entra-vs-rbac | EXPLAIN | S | Entra roles are not Azure RBAC |
| 2 | e02-create-user-and-group | CLI | S | Create a user and a security group |
| 3 | e03-invite-guest-user | PORTAL | S | Invite an external guest |
| 4 | e04-group-membership | PREDICT | S | Who is in the group? |
| 5 | e05-licence-needs-usage-location | CLI | S | Assign a licence |
| 6 | e06-pick-the-cheapest-tier | EXPLAIN | S | Pick the cheapest tier |

## Drills

| # | Folder | Skill |
|---|--------|-------|
| 1 | r01-query-users | Query users and groups with `az ad` commands |
| 2 | r02-add-group-member | Add a member to a group via CLI script |
