# a05-e03-invite-guest-user `[PORTAL]` (S)

## Goal

Invite an external guest into the **disposable A05 Entra test tenant** (never the personal Default Directory, never a work tenant). Record what you did in `ANSWER.md`. Do not change `main.bicep`.

B2B guest objects live in the resource tenant with `userType` Guest. The UPN is the guest's email with `@` replaced by `_`, then `#EXT#`, then `@` and the resource tenant's initial domain. Example shape from Learn: inviting `john@contoso.com` into `fabrikam.onmicrosoft.com` yields `john_contoso.com#EXT#@fabrikam.onmicrosoft.com`.

Source: <https://learn.microsoft.com/entra/external-id/user-properties> (section **User Principal Name** and **User type**).

## Constraints

- Directory work runs only in the A05 test tenant. Confirm the directory in the portal header before you invite anyone.
- Free tier covers inviting external / guest users (SPEC 3.2; Entra licensing: <https://learn.microsoft.com/entra/fundamentals/licensing>).
- `ANSWER.md` uses the required headings exactly, with text under each.
- Under **Steps in the test tenant**, name the blades you used and that you were in the test tenant, not the Default Directory.
- Under **UserType**, the guest's `userType` after the invite (Learn: Guest for a B2B collaboration user).
- Under **UPN shape**, the `#EXT#` UPN pattern, using obviously fake names (do not paste a real person's email).
- Do not invent CLI or Graph JSON. Do not change `main.bicep`.

Required `ANSWER.md` headings (exact lines):

- `## Steps in the test tenant`
- `## UserType`
- `## UPN shape`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
