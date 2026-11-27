# a05-e06-pick-the-cheapest-tier `[EXPLAIN]` (S)

## Goal

For each stated requirement, pick the **cheapest** Entra ID tier that satisfies it (`Free`, `P1`, or `P2`), say why, and state the 30-day-trial implication for the **A05 test tenant**. Write `ANSWER.md`. Do not change `main.bicep`.

Verify every tier claim on Learn before you write it. Start here, then follow the SSPR and PIM pages it links:

- Entra licensing: <https://learn.microsoft.com/entra/fundamentals/licensing>
- SSPR licensing (password **change** vs password **reset**): <https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing>
- Dynamic membership groups: <https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership>
- PIM getting started (licence prerequisite): <https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-getting-started>

The general Entra licensing page lists SSPR under Free, but password reset for cloud users needs P1 per the SSPR licensing page; these scenarios follow that specific page.

P1/P2 items in this course are **trial-in-test-tenant** (or EXPLAIN). The one-month P1/P2 trial requires a credit card and, when the trial ends, automatically converts into a 12-month paid subscription unless you cancel during the trial; read the terms at Start, and start it only in the test tenant. Never in a work tenant and never on the personal MSA Default Directory. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote on the one-month free trial).

## Scenarios

1. 50 cloud users must be able to reset a forgotten password themselves.
2. Group membership must follow the user's department attribute automatically.
3. Global Administrator must be activated just in time with approval, not held permanently.
4. A cloud user wants to change their own known password.

## Constraints

- `ANSWER.md` uses the required headings exactly, with text under each.
- Under **Cheapest tier**, write exactly `Free`, `P1`, or `P2` (the minimum that covers the requirement).
- Under **Why**, name the feature (SSPR reset, SSPR change, dynamic groups, PIM) and cite the Learn page you used.
- Under **Trial caveat for the test tenant**, say whether this requirement stays on Free, or needs a P1/P2 trial in the **test tenant**. The one-month P1/P2 trial requires a credit card and, when the trial ends, automatically converts into a 12-month paid subscription unless you cancel during the trial; read the terms at Start, and start it only in the test tenant. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote on the one-month free trial) and SPEC 3.2.
- Do not invent portal or CLI output. Do not change `main.bicep`.

Required `ANSWER.md` headings (exact lines):

- `## Scenario 1 Cheapest tier`
- `## Scenario 1 Why`
- `## Scenario 1 Trial caveat for the test tenant`
- `## Scenario 2 Cheapest tier`
- `## Scenario 2 Why`
- `## Scenario 2 Trial caveat for the test tenant`
- `## Scenario 3 Cheapest tier`
- `## Scenario 3 Why`
- `## Scenario 3 Trial caveat for the test tenant`
- `## Scenario 4 Cheapest tier`
- `## Scenario 4 Why`
- `## Scenario 4 Trial caveat for the test tenant`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
