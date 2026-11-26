# a04-e06-interpret-access-assignments

`fixtures/role-assignments.json` is constructed from the documented `az role assignment list` output schema, not a live capture. All-zero GUIDs and `lagb-course-example` are fake.

## Assignments
Two rows:

- **student@example.com** (User, principalId `00000000-0000-0000-0000-000000000010`) holds **Reader**.
- **lab-ops@example.com** (User, principalId `00000000-0000-0000-0000-000000000011`) holds **Contributor**.

## Scope
Reader is at the resource group `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/lagb-course-example`. That principal can read resources in that group only.

Contributor is at the subscription `/subscriptions/00000000-0000-0000-0000-000000000000`. That principal can manage resources in every group in the subscription (except where a deny assignment or a lock blocks it). Subscription scope is wider than resource-group scope; it does not grant Microsoft Entra directory roles.

## Role definition
Reader is the built-in definition `acdd72a7-3385-48ef-bd42-f606fba81ae7` (`/subscriptions/…/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7`). Built-in role ids are the same in every tenant. A custom role has a tenant-created definition id, a name you chose, and an `assignableScopes` list; it is not one of the well-known GUIDs. Contributor in this fixture is the built-in `b24988ac-6180-42a0-ab88-20f7382dd24c`.
