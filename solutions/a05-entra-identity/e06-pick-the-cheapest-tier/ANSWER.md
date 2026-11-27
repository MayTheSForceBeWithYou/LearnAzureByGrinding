# a05-e06-pick-the-cheapest-tier

Tier claims cite <https://learn.microsoft.com/entra/fundamentals/licensing> and the SSPR, dynamic-group, and PIM pages it links.

## Scenario 1 Cheapest tier
P1

## Scenario 1 Why
Cloud-only users resetting a forgotten password is SSPR **reset**, not password **change**. The general Entra licensing page lists SSPR under Free, but password reset for cloud users needs P1 per the SSPR licensing page. That table leaves Free blank for cloud-only password reset and includes it on Microsoft Entra ID P1 or P2 (and Microsoft 365 Business Standard). Cheapest of Free / P1 / P2 is P1. Source: <https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing>.

## Scenario 1 Trial caveat for the test tenant
Needs a P1 trial in the disposable A05 test tenant, never a work tenant and never the personal MSA Default Directory. The one-month P1/P2 trial requires a credit card and, when the trial ends, automatically converts into a 12-month paid subscription unless you cancel during the trial; read the terms at Start. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote on the one-month free trial) and SPEC 3.2.

## Scenario 2 Cheapest tier
P1

## Scenario 2 Why
Group membership that follows `department` automatically is a **dynamic membership group**. Dynamic membership groups require Microsoft Entra ID P1 (or Intune for Education) for each unique user in any dynamic group. Source: <https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership> and <https://learn.microsoft.com/entra/fundamentals/licensing>.

## Scenario 2 Trial caveat for the test tenant
Needs a P1 trial in the disposable A05 test tenant, never a work tenant and never the personal MSA Default Directory. Same conversion terms as scenario 1: credit card, then a 12-month paid subscription unless you cancel during the trial. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote) and SPEC 3.2.

## Scenario 3 Cheapest tier
P2

## Scenario 3 Why
Just-in-time Global Administrator with approval is Privileged Identity Management. PIM getting started lists Microsoft Entra ID P2 (or Microsoft Entra ID Governance) as the licence prerequisite. Cheapest of Free / P1 / P2 is P2. Source: <https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-getting-started>.

## Scenario 3 Trial caveat for the test tenant
Needs a P2 trial in the disposable A05 test tenant, never a work tenant and never the personal MSA Default Directory. Same conversion terms: credit card, then a 12-month paid subscription unless you cancel during the trial. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote) and SPEC 3.2.

## Scenario 4 Cheapest tier
Free

## Scenario 4 Why
A cloud user who knows their password and wants a new one is SSPR **password change**. The SSPR licensing table includes cloud-only password change on Microsoft Entra ID Free. Source: <https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing> and <https://learn.microsoft.com/entra/fundamentals/licensing>.

## Scenario 4 Trial caveat for the test tenant
Stays on Free. No P1/P2 trial. Do not start a paid-converting trial for a Free-tier password change.
