# a05-e04-group-membership

`fixtures/users-and-groups.json` is constructed from the documented Microsoft Graph user and group schema, not a live capture. All-zero GUIDs and `lagb-` names are fake.

## lagb-engineers
Assigned membership: **lagb-alex**, **lagb-dana** (ids `00000000-0000-0000-0000-000000000001` and `00000000-0000-0000-0000-000000000004`).

## lagb-finance
Assigned membership: **lagb-blair** (id `00000000-0000-0000-0000-000000000002`).

## lagb-dept-engineering
Dynamic rule `(user.department -eq "Engineering")` applied to the four fixture users: **lagb-alex**, **lagb-chris**. lagb-blair (Finance) and lagb-dana (Operations) are out. The fixture `members` array is empty because dynamic membership is computed, not assigned. You cannot manually add or remove members of a dynamic membership group (Learn, Considerations).

## Why the dynamic group is P1
Dynamic membership groups require Microsoft Entra ID P1 (or Intune for Education) for each unique user who is a member of any dynamic group. Source: <https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership> (License requirements). A P1 trial belongs only in the disposable A05 test tenant, never the personal Default Directory and never a work tenant.
