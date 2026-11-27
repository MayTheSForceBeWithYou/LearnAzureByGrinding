# a05-e03-invite-guest-user

The names below are fake, following `fixtures/NOTE.md` style. This is not a live capture.

## Steps in the test tenant
In the Azure portal, confirm the directory in the header is the disposable A05 Entra test tenant, not the personal Default Directory and not a work tenant. Open Microsoft Entra ID → Users → New user → Invite external user. Invite `lagb-guest@example.com` into that test tenant. Free covers inviting external / guest users: <https://learn.microsoft.com/entra/fundamentals/licensing>.

## UserType
Guest. A B2B collaboration user in the resource tenant has `userType` Guest. Source: <https://learn.microsoft.com/entra/external-id/user-properties> (User type).

## UPN shape
Inviting `lagb-guest@example.com` into `labtenant.onmicrosoft.com` yields `lagb-guest_example.com#EXT#@labtenant.onmicrosoft.com`. The guest email's `@` becomes `_`, then `#EXT#`, then `@` and the resource tenant's initial domain. Source: <https://learn.microsoft.com/entra/external-id/user-properties> (User Principal Name).
