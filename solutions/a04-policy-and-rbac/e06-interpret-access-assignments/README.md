# a04-e06-interpret-access-assignments `[CLI]` (S)

## Goal

Interpret mocked `az role assignment list` output and write `ANSWER.md`. This is not live Azure.

## Constraints

- `fixtures/role-assignments.json` is a course fixture. It is constructed from the documented az output schema, not a live capture. All-zero GUIDs and names such as `lagb-course-example` are obviously fake. Do not treat the file as a real tenant dump.
- `main.ps1` already calls `az role assignment list --output json` through `Get-CourseRoleAssignments`. The Pester harness replaces `az` with `Enable-AzMock` and that fixture.
- Under **Assignments**, name each principal and the role they hold.
- Under **Scope**, say which assignment is at the resource group and which is at the subscription, and what that means for access.
- Under **Role definition**, identify the Reader definition id (`acdd72a7-3385-48ef-bd42-f606fba81ae7`) and how it differs from a custom role.

Required `ANSWER.md` headings (exact lines):

- `## Assignments`
- `## Scope`
- `## Role definition`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
