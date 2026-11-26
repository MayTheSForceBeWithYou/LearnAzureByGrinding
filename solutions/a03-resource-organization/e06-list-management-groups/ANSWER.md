# a03-e06-list-management-groups

## What you listed
The fixture `fixtures/management-groups.json` is constructed from the documented `az account management-group list` output schema, not a live capture. Names such as `mg-course-example` and the all-zero GUIDs are fake. The mocked list has two groups:

- `00000000-0000-0000-0000-000000000000`, display name **Tenant Root Group**
- `mg-course-example`, display name **Course example**

`Get-CourseManagementGroups` returns both because `main.ps1` calls `az account management-group list --output json` and the Pester harness feeds that fixture through `Enable-AzMock`.

## Parent and children
Tenant Root Group has `"parent": { "id": null }` — it is the root. `mg-course-example` has parent id `/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000` (the Tenant Root Group). The fixture does not list any children of `mg-course-example`.

## Why there is no MG lab
Creating or assigning management groups needs rights a personal MSA tenant often does not have (directory-wide Management Group Contributor / User Access Administrator at the tenant root). SPEC 13.3 keeps management-group *creation* off the default path: this course covers them as `[EXPLAIN]` plus this read-only `[CLI]`. There is no management-group `[LAB]`.
