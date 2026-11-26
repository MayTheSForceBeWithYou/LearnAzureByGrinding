# a03-e06-list-management-groups `[CLI]` (S)

## Goal

Interpret mocked `az account management-group list` output and write `ANSWER.md`. This is not live Azure. There is no management-group `[LAB]` (SPEC 13.3).

## Constraints

- `fixtures/management-groups.json` is a course fixture. It is constructed from the documented az output schema, not a live capture. Names such as `mg-course-example` and all-zero GUIDs are obviously fake. Do not treat the file as a real tenant dump.
- `main.ps1` already calls `az account management-group list --output json` through `Get-CourseManagementGroups`. The Pester harness replaces `az` with `Enable-AzMock` and that fixture.
- `ANSWER.md` uses the required headings exactly.
- Under **Why there is no MG lab**, say that creating or assigning management groups needs rights a personal tenant often does not have, so this course covers them as `[EXPLAIN]` plus this read-only `[CLI]`.

Required `ANSWER.md` headings (exact lines):

- `## What you listed`
- `## Parent and children`
- `## Why there is no MG lab`

## Verify

From this folder: `pwsh -File ../../../scripts/check.ps1`. That grades *your* work. `verify-all.ps1` is the author tool; an untouched starter is supposed to fail it.
