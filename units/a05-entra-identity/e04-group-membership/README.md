# a05-e04-group-membership `[PREDICT]` (S)

## Goal

Read `fixtures/users-and-groups.json`. Predict who is in each group, then write `ANSWER.md`. Do not change the fixture or `main.bicep`.

The fixture is constructed from the documented Microsoft Graph user and group schema, not a live capture. All-zero GUIDs and `lagb-` names are obviously fake.

Two groups are **assigned** membership (you add people by id). One group is **dynamic**: the rule is `(user.department -eq "Engineering")`. Dynamic membership groups require Microsoft Entra ID P1 (or Intune for Education) coverage for each unique user in any dynamic group. Source: <https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership> (section **License requirements**). Mark that group P1 / trial-in-test-tenant; this course does not create dynamic groups on Entra ID Free.

## Constraints

- `ANSWER.md` uses the required headings exactly, with text under each.
- Under each group heading, list the member **display names** (and say `none` if empty). For the dynamic group, apply the rule to the four users; do not assume extra people exist.
- Under **Why the dynamic group is P1**, cite the licensing sentence from the dynamic-membership page, and that a P1 trial belongs only in the A05 test tenant. The one-month P1/P2 trial requires a credit card and, when the trial ends, automatically converts into a 12-month paid subscription unless you cancel during the trial; read the terms at Start, and start it only in the test tenant. Source: <https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id> (footnote on the one-month free trial).
- You cannot manually add or remove members of a dynamic membership group (same Learn page, **Considerations**).
- Do not invent Graph or portal output. Do not change the fixture.

Required `ANSWER.md` headings (exact lines):

- `## lagb-engineers`
- `## lagb-finance`
- `## lagb-dept-engineering`
- `## Why the dynamic group is P1`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
