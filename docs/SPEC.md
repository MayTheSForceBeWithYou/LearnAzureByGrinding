# Spec: Learn Azure by Grinding

Version 0.3 (Phase 1, exercise/drill and pedagogy reviews of 21 November 2026 applied).
Owner: Bruce (harness, CI, `docs/SPEC.md`, technical review). This file is the plan of
record. When it disagrees with another document, this file wins; fix the other document
and tell its owner.

The skills outline in section 5 follows the official study guide for Exam AZ-104:
Microsoft Azure Administrator, fetched on 20 November 2026 from
<https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104>.
**Authors must re-open that page at the start of each unit's authoring and again at Phase 3
review**, and update this file if the "Skills measured as of" heading, domain weights, or
task bullets have changed.

A note on dates, so nobody papers over it: the certification page
(<https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/>)
was marked **Last Updated 04/17/2026** when checked on 20 November 2026, and its audience
profile already says experience with "Azure Resource Manager templates or Bicep files." The
study guide URL, fetched the same day, still headed the outline **"Skills measured as of
October 26, 2023."** Independent write-ups that say they checked the same official guide on
9 October 2026 and 17 November 2026 report the live heading as **"Skills measured as of
April 17, 2026."** Microsoft's changelog for that date marks only **Minor** edits (audience
profile; Configure Azure Files and Azure Blob Storage; Create and configure virtual machines;
Provision and manage containers in the Azure portal; Configure and manage virtual networks
in Azure; Monitor resources in Azure). Domain names and weight ranges did not change. The
task bullets in the coverage matrix (section 5.3) are the full official list from the 20
November 2026 study-guide fetch, which matches those write-ups at sub-heading level. If a
later fetch disagrees, the page wins and this file is updated.

## 1. Why this exists

Nathan wants to be confident taking and passing the Microsoft Azure Administrator Associate
exam (AZ-104), and he wants to get there the same way he learned C memory and data
structures: by grinding, not by watching a video tour of the portal.

The exam is operational. It measures identities and governance, storage, compute, virtual
networking, and monitoring. Only one official sub-heading is "write, modify, and deploy ARM
templates or Bicep files." The rest is things an administrator does with Entra, the portal,
the CLI, and PowerShell. This course is nevertheless **Infrastructure-as-Code first.**
Bicep is the primary language. ARM JSON is a first-class literacy: students read it, modify
it, export it, and decompile it, because the exam still asks for that. Skills that cannot
honestly be expressed as a template (Entra users, Storage Explorer, effective NSG rules,
backup restore, a VM move) are taught as gated `[PORTAL]` / `[CLI]` / `[LAB]` work, not
faked as Bicep.

It is built the same way as `LearnCDataStructuresByGrinding`: a written plan of record, a
lesson then exercises then drills, starters that fail until the student does the real work,
a separate `solutions/` tree that no README links to, a verify script that grades both
starters and solutions, and CI that proves the offline path on every pull request.

## 2. Goals

After the course, without looking anything up beyond Microsoft Learn and `az --help` /
`Get-Help`, the student can:

- write, read, and modify Bicep and ARM JSON for the resource types AZ-104 covers, and say
  which deployment scope a given file belongs at;
- preview a deployment with what-if, interpret change types, and validate a template
  without applying it;
- express governance (resource groups, tags, locks, Policy, RBAC, budgets) and the usual
  storage, network, compute, and monitor resources as Bicep, with a local test that would
  fail if a required type or property were missing;
- do the portal- and CLI-only work the exam actually asks for, and explain what the portal
  is doing that a template cannot;
- tear down every lab they create, read a budget, and find leftover course-tagged
  resources, so a learner subscription does not become a surprise bill;
- sit the official AZ-104 practice assessment and recognise every skills-outline bullet as
  something they have already done or explained.

### Anti-goals

- Not a general cloud-architecture course, and not AZ-305, AZ-700, or AZ-800.
- Not a Kubernetes, AKS, Terraform, Pulumi, or Ansible course. AKS appears only if the
  official outline adds it; as of the 20 November 2026 fetch it is not a named AZ-104
  bullet.
- Not a vendor practice-question dump. Exam readiness uses Microsoft's own practice
  assessment and a coverage review, not brain dumps.
- Not a production landing-zone framework (CAF/ALZ verbatim). Capstone 1 is a small,
  testable governance baseline a student writes, not a fork of the official ALZ repo.
- CI never deploys to Azure. Live labs run on the learner's machine, against the learner's
  subscription, under the cost rules in section 10.

## 3. Environment

This course is **Windows-first.** That is a deliberate departure from the Arch-Linux-on-WSL
rule of the C grinding courses. The student's work folder is
`C:\Users\n8ppr\dev\Azure\LearnAzureByGrinding` on the Windows machine. Scripts are
PowerShell 7 (`.ps1`). CI also proves the offline path on Ubuntu with `pwsh`.

| | Student workstation (Windows) | CI: `windows-latest` | CI: `ubuntu-latest` |
|---|---|---|---|
| Shell | PowerShell 7.4+ (`pwsh`) | `pwsh` | `pwsh` |
| Azure CLI | 2.76.0 or later (needed for `--validation-level`); 2.88.0 or later if a script uses `az bicep run --config` | same minimum, pinned in CI | same |
| Bicep CLI | 0.49.2, pinned in `scripts/toolchain.psd1` (standalone); same pin in CI | installed at the pin | installed at the pin |
| Pester | 5.9.1, pinned in `scripts/toolchain.psd1` (not the Windows-PowerShell in-box 3.4.0) | 5.9.1 | 5.9.1 |
| PSRule for Azure | `PSRule.Rules.Azure`, version and baseline pinned in `scripts/toolchain.psd1` | `scripts/psrule.ps1` and verify-all (not the `microsoft/ps-rule` action) | same |
| Editor | VS Code + Bicep extension, optional | n/a | n/a |
| Azure login | required only for `[LAB]`, live `[WHATIF]`, and some `[CLI]` work | **none** (no credentials in the default workflow) | none |

Exact pinned versions live in `scripts/toolchain.psd1` (the single source of pins),
documented in `docs/AUTHORING-INFRA.md`, and installed or checked with
`scripts/install-tools.ps1`. Phase 1 infra recorded them on `DESKTOP-AK42M6F` and on
both CI images (Bicep CLI 0.49.2, Pester 5.9.1, PSRule 2.9.0, PSRule.Rules.Azure
1.47.0, baseline `Azure.Pillar.Security.L1`; see section 9). Bumps are a deliberate PR.

`bicep snapshot` exists in the pinned Bicep CLI 0.49.2 and stays **optional** in
verify-all (section 13.3). The official Bicep CLI page already describes it;
`az bicep snapshot` does not exist, so snapshots are invoked as `bicep snapshot`
directly.

On Windows, install Pester 5 with `-Force -SkipPublisherCheck` so it sits beside, and is
preferred over, the in-box 3.4.0 module. All course scripts must run under `pwsh`, not
Windows PowerShell 5.1.

### 3.1 Workstation and toolchain

The table and pin policy above are the toolchain rules. Exact CLI and module versions
are recorded in Phase 1 after they have been installed and checked on
`DESKTOP-AK42M6F` (see section 13.2). Until then this spec states minimums only.

### 3.2 Tenant and subscription setup (beginner)

This section is for Nathan's personal Microsoft account
`MayTheSForceBeWithYou@gmail.com`, and for any later learner who signs in with a
personal Microsoft account (MSA). Facts were checked against Microsoft Learn and
official Azure / Entra pages on 20 November 2026. Re-open the cited pages if a
portal label has moved.

#### What a personal MSA tenant is

A **personal Microsoft account** (MSA) is a Microsoft account a person signs in with,
as opposed to a work or school account. Nathan signs in with his existing Gmail-based
personal Microsoft account, `MayTheSForceBeWithYou@gmail.com`. Microsoft did not issue
or create that Gmail address; it is the sign-in he already uses for the MSA.

When he signs up for Azure or first signs in to the Azure portal with that MSA,
Azure uses or creates a **Microsoft Entra ID tenant** for that personal account.
In the portal it is often named **Default Directory**, and it gets an initial domain
like `something.onmicrosoft.com`. The MSA is the first user in that directory (and
usually a Global Administrator). That tenant is *your* personal Entra directory. It
is not Deloitte's, and it is not a company's work/school tenant.

A **work or school tenant** is an organization's Entra directory: a company domain,
many users and groups, company Conditional Access and device policy, and often a
hybrid link to on-premises Active Directory. Signing in with a work account
(`@deloitte.com` or similar) lands you in *that* organization's tenant. Labs in this
course must never run there.

Two caveats, so the portal does not surprise you:

- If `MayTheSForceBeWithYou@gmail.com` was already invited into another tenant (as a
  guest or member), a new Azure subscription might attach to *that* tenant instead of
  a fresh Default Directory. Always confirm the active tenant with
  `az account show` and `az account list --output table` before any lab.
- A 2026 Microsoft Q&A thread claimed some portal flows now prefer a work/school
  sign-in. Official Learn material still describes signing in with an MSA and using
  the Default Directory that creates. If the portal refuses the MSA for a particular
  admin blade, create a cloud-only Entra *user* in the personal directory, make it a
  Global Administrator, and use that user for directory admin work, while keeping the
  MSA as the Azure billing owner. Do not solve this by signing in to a work tenant.

Official starting points:

- Create / switch tenants: <https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant>
- Azure account offers: <https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account>
- Always-free and free-tier services: <https://azure.microsoft.com/en-us/pricing/free-services>

#### Recommendation: personal subscription for Azure labs, disposable Entra tenant for A05

Use **two directories**, both under your control, and never a work tenant:

1. **Personal MSA tenant + its Azure subscription** for resource labs **A00–A04 and
   A06–A17** (resource groups, storage, networks, VMs, apps, monitor, backup, and so
   on). This is the subscription you put the A02 budget on, and the tenant you pin
   in `.lab-env.json` (below).
2. **A dedicated, disposable Microsoft Entra ID test tenant** for **A05** (users,
   groups, external/guest invites, SSPR, dynamic groups, Conditional Access, and any
   later PIM exploration). Create it from the same Azure portal while signed in as
   the personal MSA. Test users, guest invites, SSPR, and Conditional Access policies
   then live in the test directory. They never clutter, lock out, or Conditional-Access
   your personal Default Directory (the one that owns your Azure subscription and your
   Gmail sign-in).

Do not author A05 exercises that modify production or work users. The A05 lesson
states this tenant rule before the first task.

#### How to create the Entra ID test tenant and switch directories

From the official quickstart
(<https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant>), checked
20 November 2026:

**Prerequisite:** Microsoft documents that **only paid customers can create an
additional Workforce tenant**. A free or trial-only Entra tenant, or a subscription
that is still on the Azure Free trial and has not converted, may be blocked from
**Create**. A Pay-As-You-Go (PAYG) subscription under the same MSA is the usual way
past that gate. If Create is disabled, confirm you are in the personal directory,
that tenant creation is not turned off on the user settings page, and that the
signed-in user has the Tenant Creator role (the MSA owner usually does). A documented
fallback is a separate Microsoft 365 Developer Program test tenant, used only for
A05, still never a work tenant. That Developer Program tenant **expires** (the
program's current term is time-limited and must be renewed or replaced); do not
treat it as a permanent directory, and do not put lasting personal work there.

Create a **Workforce** tenant, not B2C and not an External ID customer tenant:

1. Sign in to the Azure portal at <https://portal.azure.com> with
   `MayTheSForceBeWithYou@gmail.com`, in the **separate browser profile** described
   below.
2. Open **Microsoft Entra ID**.
3. Go to **Entra ID → Overview → Manage tenants**.
4. Select **Create**.
5. On **Basics**, choose **Microsoft Entra ID** (Workforce). Do not choose
   **Microsoft Entra ID (B2C)**.
6. On **Configuration**, enter an obvious lab name (for example `LearnAzureByGrinding-A05`),
   an initial domain prefix (this becomes `yourprefix.onmicrosoft.com`), and a
   country/region (United States is fine).
7. **Review + Create**, then **Create**. You are Global Administrator of the new
   tenant. Microsoft recommends two emergency-access ("break glass") cloud-only
   Global Administrator accounts in any directory you intend to keep.
   For this disposable A05 tenant, prefer a couple of clearly named lab admin users
   instead, and delete the tenant when A05 is finished
   (<https://learn.microsoft.com/en-us/entra/fundamentals/create-new-tenant>).

Switch directories cleanly, every time you move between resource labs and A05:

- In the Azure portal, open the **Directories + subscriptions** filter (the filter /
  gear control in the portal header, sometimes labelled **Directory + subscription**)
  and switch to the personal Default Directory for A00–A04, A06–A16, and A17 work
  that is not Entra review, or to the A05 test tenant for A05 and for A17 Entra
  walkthroughs. Confirm the subscription list matches the directory you expect
  (the A05 tenant may have no subscription, and that is fine).
- In Azure CLI, never rely on "whatever I last logged in to":

  ```powershell
  az login --tenant <personal-tenant-id>
  az account set --subscription <personal-subscription-id>
  az account show
  az account list --output table
  ```

  For A05 Graph/CLI work, `az login --tenant <a05-test-tenant-id>` and confirm
  `tenantId` before creating users. Any A05 directory script, and `lab-up.ps1` when
  the unit is A05, must also match `.lab-env.json`'s `expectedEntraTenantId` (below)
  or refuse to run. `lab-up.ps1` / `lab-down.ps1` for *resource* labs always use the
  personal tenant and subscription pinned as `expectedTenantId` and
  `expectedSubscriptionId`; they must not target the A05 directory for resource
  deployments.

#### Entra ID Free versus P1 / P2, and the 30-day trial

**Works on Entra ID Free** (enough for a large part of A05, in the test tenant):

- Create and manage cloud users and groups, and their basic properties
- Invite external / guest users
- Azure RBAC assignments on the subscription or resource group (that is Azure
  resource access, taught in A04, not an Entra P1 feature)
- SSPR *password change* for cloud-only users (the user knows their current
  password and changes it). This is not the same as password *reset*.

**Needs Entra ID P1** (or a Microsoft 365 plan that includes P1):

- Dynamic groups
- Conditional Access
- SSPR *password reset* and the group-based / on-premises / advanced SSPR features
  the exam talks about. Official licensing:
  <https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-licensing>

**Needs Entra ID P2** (only if an exercise explores them; not required for every A05 path):

- Privileged Identity Management (PIM)
- Entra ID Protection / risk-based Conditional Access

A05 authors cover the Free tasks as the default path, and mark P1/P2 tasks clearly
as optional labs that require a trial (or are `[EXPLAIN]` plus a Microsoft Learn
sandbox if a trial is not available).

**30-day P1/P2 trial (2026):** Microsoft's Entra ID product page
(<https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id>)
describes a short P1/P2 trial that requires a payment method and, in the terms shown
on that page, **can automatically convert to a paid 12-month subscription unless it
is canceled during the trial**. Always read the trial terms *at the moment you click
Start*, and check **Recurring billing** in the Microsoft 365 admin center for that
tenant (some trials show Recurring billing Off and expire without converting; do
not assume).
Start the trial only in the **A05 test tenant**, never in a work tenant and never as
a licence you leave assigned on your personal MSA. Cancel before the last day, or
confirm the trial is set not to convert, and remove any paid P1/P2 licence
assignments you do not intend to keep. Do not buy paid licences "just in case."

#### Azure Free Account versus Pay-As-You-Go

The **Azure Free Account** (new customers) includes:

- a **$200** credit that can be used in the first **30 days**
- limited quantities of popular services **free for 12 months**
- a set of **always-free** services with monthly allowances

Official offer pages (re-check when you start A02):

- <https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account>
- <https://azure.microsoft.com/en-us/pricing/free-services>

The $200 credit is generally **once per new customer**. If
`MayTheSForceBeWithYou@gmail.com` already used that free trial, the account is (or
will be) **Pay-As-You-Go**. PAYG still bills only for usage beyond what remains
free: the always-free monthly allowances still apply. The 12-month free quantities
are a new-customer benefit; do not assume they still apply after a previous trial.
In the portal, open **Cost Management + Billing** for the personal subscription and
read the offer type. Labs in this course are written so a careful PAYG student who
tears down after each `[LAB]` should stay near the A02 budget, not near a surprise
bill. Always-free and cheap SKUs are preferred; costly labs are **Optional**
(section 10.7).

#### Budget alerts (A02)

In A02, create a **low monthly budget** on the personal lab subscription, in the
range **$10–$25 per month**, with five notifications (an Azure budget allows at
most five): **Actual** cost at **50%, 80%, and 100%**, plus **Forecasted** cost at
**80% and 100%**. There is no sixth slot for a Forecasted 50% alert. Send them to
Nathan's personal email (not a work address). Official tutorial:
<https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets>.
This `[LAB]` is the gate for every later live lab. `lab-up.ps1` refuses to deploy
later resource labs until it can see a subscription budget whose name matches
`.lab-env.json` `budget.name` and whose amount is greater than 0 (or until an
explicit, loudly logged override is set). Details are in section 10.3.

#### Deloitte / work-tenant isolation guardrails

Nothing in this course may touch a Deloitte or other work tenant, subscription, or
directory. Concrete steps, all of them required:

1. **A separate browser profile** used exclusively for
   `MayTheSForceBeWithYou@gmail.com` and the personal Azure / Entra directories.
   Do not sign that profile into a work account. Do not use the work browser
   profile for these labs.
2. **Before every lab**, in `pwsh`:

   ```powershell
   az account show
   az account list --output table
   ```

   Confirm the tenant is the personal tenant and the subscription is the personal
   PAYG (or free) subscription. If it is not, run
   `az login --tenant <personal-tenant-id>` and `az account set --subscription
   <personal-subscription-id>`, then look again.
3. A **gitignored** `.lab-env.json` at the repo root, created locally (never
   committed) from `.lab-env.example.json`. Required pins:

   ```json
   {
     "expectedTenantId": "<personal-msa-tenant-guid>",
     "expectedSubscriptionId": "<personal-subscription-guid>",
     "expectedEntraTenantId": "<a05-disposable-test-tenant-guid>"
   }
   ```

   `expectedTenantId` is the personal Default Directory used for resource labs.
   `expectedEntraTenantId` is the disposable A05 test tenant, and is **not** the
   personal Default Directory.

   The same file also carries (defaults in parentheses):

   - `prefix` (`lagb`), `location` (`eastus`), `owner` (`n8`)
   - `budget.name` (`lagb-monthly`): name of the A02 subscription budget. The
     budget gate looks for exactly this name.
   - `budget.amount` (`25`): monthly amount the A02 deployment uses. The gate does
     **not** compare against this field; it only requires the found budget's amount
     to be greater than 0.
   - `budget.contactEmail`: required for A02; the address the budget alerts and the
     action group email (Nathan's personal address, not a work address).
   - `guardrails.resourceGroup` (`lagb-guardrails`): the persistent group that
     holds the budget's action group (section 10.3). Keep the name under `<prefix>-`
     so `lab-down -IncludePersistent` can still select it.

   An optional `allowedCustomDomains` list names verified custom domains that are
   yours (for example `skopekreep.com` if you add it to the tenant). An optional
   `corporatePatterns` list adds extra substrings that mark a work tenant; `deloitte`
   is always built in and cannot be allowlisted away.

4. `scripts/lab/lab-up.ps1` and `scripts/lab/lab-down.ps1` **must** read that file and
   **refuse to run** if the file is missing, if the pin does not match, or if the
   active tenant **looks corporate**. Corporate detection is strict:

   - The tenant display name, default domain, any verified domain, or the signed-in
     user name contains `deloitte` (or a `corporatePatterns` entry), even if that
     domain is listed in `allowedCustomDomains`.
   - The tenant has a verified domain that is not `*.onmicrosoft.com` and is not in
     `allowedCustomDomains`. Work directories always have custom domains; a personal
     Default Directory does not, unless you add one and allowlist it.

   Scope still applies:

   - For resource labs (A00–A04, A06–A17 except A17 Entra review): the active tenant
     and subscription must match `expectedTenantId` and `expectedSubscriptionId`.
   - For A05 (and A17 Entra walkthroughs that create or modify directory objects):
     the active tenant must match `expectedEntraTenantId`. Every A05 Graph/CLI
     user-creation or directory script must make the same check, even if it is not
     invoked through `lab-up.ps1`. A missed `az login --tenant` must not be able to
     mutate the personal Default Directory.

   The refusal is a hard error, not a warning the student can click past.

Phase 1 infra implements those checks; this spec is the rule they implement.

## 4. Structure

### 4.1 Units, lessons, exercises, drills

The course has **18 units** (`A00`–`A17`) and **3 capstones** (`C1`–`C3`), about **108
exercises** and **36 drills** (section 5; counts are targets, frozen by folder name when
Phase 2 authors the unit). Unit ids follow the C courses (`D07` became
`units/d07-<slug>/`): unit `A12` is the folder `units/a12-virtual-machines/`.

```
units/a06-storage-accounts/
├── LESSON.md                  # the reading
├── e01-storage-account/       # exercise: README.md, exercise.psd1, starter Bicep, Pester harness
├── e02-redundancy/
├── lesson-demo/               # optional: snippets or captures a lesson quotes
└── drills/
    ├── README.md
    └── r01-sku-and-kind-reps/
solutions/a06-storage-accounts/
├── e01-storage-account/       # complete template + NOTES.md + the same harness
└── drills/r01-sku-and-kind-reps/
```

- **Exercise id**: `aNN-eNN-<slug>` (e.g. `a06-e01-storage-account`), always the full form.
- **Drill id**: `aNN-rNN-<slug>` (e.g. `a06-r01-sku-and-kind-reps`). `r` is for "rep."
- **Capstone id**: `cN-<name>`, folder `capstones/cN-<name>/`, with a unit-level
  `LESSON.md` or README and `eNN-<slug>/` exercise folders (same format as unit
  exercises). Solution: `solutions/capstones/cN-<name>/`.
- A Pester structural test that passes prints `<id>: all checks passed` and exits 0, the
  same contract as `checks_done("<id>")` in the C courses.

### 4.2 Exercises versus drills

| | Exercise | Drill |
|---|---|---|
| Purpose | learn a resource, a template pattern, or a portal/CLI skill | make one skill automatic by repetition |
| Tags | any (section 4.3); `Tags` is a string array, first tag primary | always `Tags = @('DRILL')` only |
| Size | S or M (L for capstones and some `[LAB]`s); see section 7.8 | XS or S; see section 7.8 |
| Done | once, to "clean everywhere" (section 8.4) | at least 3 reps on different days, each from a fresh copy (`scripts/rep.ps1`) |
| README | goal, constraints, verify, at most one hint | skill, rules, time target, verify; no hint |
| Builds on | the unit's lesson and earlier exercises | nothing: self-contained |
| Live Azure | only if tagged `[LAB]` | never in CI or in `verify-all`; optional student-run live `az` is allowed only where a README says so (A05), and is not the graded path |

A Bicep drill follows the `[WRITE]` pattern: the starter is valid Bicep, `bicep build`
succeeds, and a Pester structural test over the compiled JSON fails until the student
writes the resources.

A CLI or PowerShell drill (A05, and any other non-Bicep drill) is still tagged only
`[DRILL]`. The student writes a script (for example `main.ps1`) below a marker. The
starter must be valid PowerShell: it **parses**. A Pester test fails until the script
implements the required commands. Verification is **offline**: tests invoke the script
against a checked-in fixture under the exercise's `fixtures/` directory, or through a
mock of `az` / `Get-Az*` in `lib/`. The script must accept a test hook (for example
`-Context`, or a wrapper the tests inject) so `verify-all` never needs a live login.
Live `az` against the A05 test tenant is optional, student-run, never part of CI, and
still subject to the `expectedEntraTenantId` refusal in section 3.2.

### 4.3 Tags

| Tag | Student... | Starter state (the fail-until-worked rule) |
|---|---|---|
| `[WRITE]` | writes the missing resources, properties, or outputs in Bicep | Valid Bicep: `bicep build`, `bicep lint`, and PSRule **succeed**. Required *types* in `ExpectResources` (and optional `ExpectOutputs`) are absent. The Pester structural test over the compiled JSON **fails** until the student writes the real resources. No dummy resources that satisfy the test, no broken syntax, no `#disable-next-line` or commented-out stop lines to delete. |
| `[MODIFY]` | changes an existing Bicep file or ARM JSON in a stated way | The file already contains the resource types. `bicep build`, `bicep lint`, and PSRule **succeed**. verify-all checks `ExpectProperties` (not a missing type). The property test **fails** until the student makes the stated change. |
| `[DRILL]` | implements a small, repeatable Bicep or CLI/PowerShell skill | Bicep drills: same fail rule as `[WRITE]`. CLI/PowerShell drills: the starter parses; a Pester test fails until the script implements the required commands (section 4.2). |
| `[BUG]` | finds and fixes a real misconfiguration, and explains it in `ANSWER.md` | `bicep build` **succeeds**. The starter may fail exactly the lint or PSRule rule(s) named in `ExpectDiagnostics = @('...')`. Those expected failures are the starter-fail condition, not an authoring bug. Unexpected lint or PSRule failures on a `[BUG]` starter *are* authoring bugs. The matching solution is clean of those diagnostics. A Pester test may also be the advertised defect. After the fix, those checks pass. |
| `[PREDICT]` | writes the outcome first (resource types, lint findings, change types, a cost or size), then runs the offline check | The starter compiles. The prediction lives in `ANSWER.md` or a filled table; it is compared by hand to a capture or program printout, as in `d00-e01-layout-predict`. |
| `[WHATIF]` | predicts what-if change types (Create, Modify, Delete, NoChange, Ignore, …) before looking | Offline default: a checked-in what-if JSON fixture that is **real command output**. If the capture is not yet taken, the file must contain `OUTPUT-PENDING`, which fails verify-all and blocks merge. Never invent a payload. Live what-if, when used, is also tagged `[LAB]`, is never run in CI, and needs a login. |
| `[EXPLAIN]` | writes a short, specific explanation in `ANSWER.md`; no required code change | The shipped file, if any, already compiles and its automated checks pass. The graded artefact is `ANSWER.md`. |
| `[LAB]` | deploys to the learner subscription, then verifies with CLI or Pester post-deploy assertions, then tears down | Offline checks may already pass. The live deploy is **gated** (section 10) and **never part of CI**. `verify-all` only checks that the lab scripts and offline tests exist and that the starter/solution still satisfy the offline rules for their other tags. |
| `[PORTAL]` / `[CLI]` | does a task that cannot honestly be graded from a template alone | Default verification is an **offline fixture** plus a script that CI runs against that fixture. Live portal steps, when present, are documented in the README and checked through `ANSWER.md` headings, not by CI logging into Azure. May combine with `[LAB]`. |
| `[NO-LIVE]` | (optional marker) this exercise must not call Azure, even if it looks live | **Implicit for every tag except `[LAB]`.** Use the marker on exercises that might look live (`[WHATIF]`, `[CLI]`) but must not call Azure. verify-all fails the exercise if its tests or scripts would call `az`, `Connect-AzAccount`, or ARM without a mock or fixture. `[LAB]` is the only tag that may require a login, and `[LAB]` is never run in CI. |

`[PORTAL]` and `[CLI]` may appear together when either interface is acceptable.
`exercise.psd1` stores them as a string array, for example `Tags = @('CLI', 'PORTAL')`.
The first tag is the primary tag and selects the fail-until-worked rule; additional
tags are modifiers (`LAB`, `NO-LIVE`, and so on). A drill is always `Tags = @('DRILL')`.

**Why `[WRITE]` compiles but the test fails.** Nathan's standing rule is that a starter
must fail until the student does the real work, with no dummy stubs and no stop lines. In
the C courses that is "compiles with `-Werror`, fails to link on exactly `EXPECT_SYMBOLS`."
Bicep has no link step. Forcing a compile failure would mean broken syntax or a
`#disable` / commented resource the student deletes — the same class of stub the C courses
forbid. So `bicep build` is the compile step and the Pester structural test is the link
step. `EXPECT_RESOURCES` (and optional `EXPECT_OUTPUTS`) in `exercise.psd1` is the symbol
list for `[WRITE]`: verify-all requires the starter's compiled JSON to be **missing**
those types (or fail the named Pester tests), and the solution's JSON to satisfy them.
`[MODIFY]` uses `ExpectProperties` instead: the type is already present; the stated
property is not, until the student edits it.

**Skills that are portal- or CLI-only in this course** (they may still have a Bicep
prelude, but the exam skill itself is verified as `[PORTAL]` / `[CLI]` / `[LAB]`):

- Entra: create and manage users and groups, properties, licences, external users, SSPR
- Interpreting access assignments (the portal/CLI picture, not only a roleAssignment resource)
- Azure Storage Explorer and AzCopy
- "Provision and manage containers in the Azure portal" (portal walkthrough in A13, in
  addition to Bicep for ACR/ACI/ACA)
- Evaluating effective NSG security rules
- Network Watcher and Connection Monitor
- Backup and restore operations; Site Recovery failover to a secondary region; backup
  reports and alerts
- Moving a virtual machine to another resource group, subscription, or region
- Mapping an existing custom DNS name to an App Service
- Interpreting Azure Monitor metrics and Insights; ad-hoc KQL over live logs
- Advisor recommendations as seen in the portal
- Troubleshooting network connectivity and load balancing with live diagnostics

### 4.4 The rule that never bends

**Every `[WRITE]`, `[DRILL]`, and `[MODIFY]` starter fails its structural (or script)
test until the student does the real work, and that failure is the test, not a compile
or parse error.**

- A Bicep or ARM `[WRITE]` / `[MODIFY]` starter is legal. `bicep build`, `bicep lint`
  (with the course `bicepconfig.json`), and PSRule succeed. A compile, lint, or PSRule
  error on these starters is an authoring bug, and verify-all reports it as one.
- `[WRITE]` (and Bicep `[DRILL]`) assertions use `ExpectResources` (required resource
  types that must appear) and optional `ExpectOutputs`. The starter's compiled JSON is
  missing those types; the tests fail until the student writes them.
- `[MODIFY]` starters already contain the resource types. verify-all checks
  `ExpectProperties` and does **not** require the starter to omit the type. The starter
  fails the property test until the student makes the change. Example field:

  ```powershell
  ExpectProperties = @(
    @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Value = 'Standard_GRS' }
  )
  ```

- A CLI/PowerShell `[DRILL]` starter is valid PowerShell (it parses). A Pester test
  fails until the script implements the required commands (section 4.2).
- No dummy resource that satisfies a test, no `todo` output the test treats as success,
  no `#disable-next-line`, no commented-out resource the student "uncomments," no README
  that says "delete this line to continue."
- Manifest fields must match what the tests enforce. verify-all checks that the starter
  fails those tests and that the failure is about the expected types, properties, or
  commands — not a crash, and not an unexpected lint or PSRule error.

`[BUG]` starters must still `bicep build`. They may fail exactly the lint or PSRule
rule(s) named in `ExpectDiagnostics = @('...')`. verify-all treats those expected
failures as the starter-fail condition, not as an authoring bug. Unexpected lint or
PSRule failures on a `[BUG]` starter are still authoring bugs. The matching solution
must be clean of those diagnostics. `[EXPLAIN]` / `[PREDICT]` starters compile (and
are lint- and PSRule-clean) and their automated checks pass (the prose is the work).

That rule is **approved** (20 November 2026). Here is why it is written this way, in
plain language.

In the C grinding courses, a `[WRITE]` starter is legal C: it **compiles**, and then it
**fails to link** or fails a unit test, until you write the real function. The compiler
is not the teacher of the algorithm; the linker or the test is. A starter that is
deliberately illegal C would only teach you to hunt syntax errors, which is not the
skill the exercise is about.

This course uses the same discipline in Bicep:

1. You run `verify` (or `verify-all.ps1`). The starter **builds**: `bicep build` and
   `bicep lint` succeed. The file is legal Bicep, and the course linter is happy.
   There is no stub that stops compilation, and no "delete this line to continue."
2. The same `verify` then runs a **Pester structural test** over the **compiled JSON**.
   The test looks for the resources, properties, or outputs the exercise asked for. On
   a starter those are missing, so the test **fails**. That red result is the expected
   starting state. It is the Bicep analogue of "this compiles but will not link."
3. You write the real resources below the starter marker and run `verify` again.
   `bicep build` was already green; what changes is that the compiled template now
   contains the work, and the structural tests go green.
4. If `bicep build` itself fails after you edit, that is a syntax or linter problem in
   what you wrote (or a bug in the starter). Fix the Bicep first. The structural test
   is only meaningful on a template that compiles.

A CLI or PowerShell drill is the same idea in a different language: the starter
parses, and the Pester test stays red until the script does the work.

### 4.5 Verification layers

| Layer | Tools | Needs an Azure login? | In `verify-all` / CI? |
|---|---|---|---|
| Compile | `bicep build`, `bicep build-params` | No | Yes |
| Lint | `bicep lint` with the repo `bicepconfig.json`. Enabled course rules are set to `warning` (not `Error`); the harness fails on any warning, like `-Werror`. `[WRITE]` / `[MODIFY]` starters must be lint-clean. `[BUG]` starters may fail only the rule ids in `ExpectDiagnostics` | No | Yes |
| Snapshot | `bicep snapshot` on a `.bicepparam`, only if the pinned CLI treats it as stable | No | Optional (section 13.2) |
| Resource / WAF rules | `PSRule.Rules.Azure` with `AZURE_BICEP_FILE_EXPANSION: true` in `ps-rule.yaml`, baseline `Azure.Pillar.Security.L1`. `[WRITE]` / `[MODIFY]` starters must be PSRule-clean. `[BUG]` starters may fail only the rule ids in `ExpectDiagnostics` | No | Yes, via `scripts/psrule.ps1` and verify-all (not the `microsoft/ps-rule` action) |
| Structural tests | Pester 5, over compiled JSON and, for solutions, over expected outputs | No | Yes |
| ARM JSON style | `arm-ttk`, **optional, A01 only**, for raw ARM JSON exercises | No | Optional; not the default language test (Bicep already contains the deploymentTemplate TTK cases; new investment is the Bicep linter; arm-ttk 0.27 remains available for JSON / createUiDefinition) |
| Preflight | `az deployment group validate --validation-level Provider\|ProviderNoRbac\|Template` (CLI 2.76+) | Yes | No (a `[LAB]` step the student runs) |
| What-if | `az deployment group what-if` (and sub / mg / tenant when the exercise is at that scope) | Yes, unless the exercise uses a checked-in fixture | Fixture: yes. Live: no |
| Post-deploy | Pester + `az` / Az PowerShell assertions | Yes | No |
| Portal / CLI skills | script + checked-in fixture; `ANSWER.md` headings where the README requires prose | No for the default path | Yes: the fixture script runs. Live portal/CLI steps are not replayed. `ANSWER.md`, when required, must exist, be non-empty, and contain every required heading (quality of prose is not graded) |

Linter rules are `warning` in `bicepconfig.json` because Bicep 0.49.2 makes `bicep build`
**fail** on an error-level linter diagnostic. A `[BUG]` starter whose defect is a
linter rule must still compile so its Pester harness can run. The harness (`Get-LintFindings`)
treats every warning and error as a finding, so a warning still fails the exercise,
exactly as the C courses compile with `-Werror`. `lint.ps1` rejects any rule set to
`error`.

The PSRule baseline is `Azure.Pillar.Security.L1` (mapped to the `@course` group in
`ps-rule.yaml`). Full `Azure.GA_*` baselines were not used: they fail rules such as
`Azure.Storage.UseReplication` on `Standard_LRS` and `Azure.Resource.UseTags` on
untagged resources, which contradicts section 10.4 (prefer Standard_LRS) and would
bury beginners. PSRule runs through `scripts/psrule.ps1` and verify-all, not the
`microsoft/ps-rule` GitHub Action, so `[BUG]` starters can fail named rules on
purpose without a separate action treating that as a CI failure. **Pending for A07:**
whether `Azure.Storage.LocalAuth` (in Security L1) needs a documented suppression.
A07 teaches SAS tokens, stored access policies, and access keys, which use shared-key
/ local authentication; that rule wants local auth disabled. Do not invent a
suppression until that question is decided.

`az bicep build` / `az bicep lint` do not take `--config`. Course scripts call the Bicep
CLI directly (`bicep lint --config ./bicepconfig.json`) so the repo config is always the
one that is used. If a script must go through Azure CLI, it uses `az bicep run --command
"..."` on Azure CLI 2.88.0 or later.

Preflight and what-if are best-effort: what-if cannot resolve `reference()` and may report
spurious Modify; nested `templateLink` / template-spec resources may be invisible;
expansion limits (500 nested templates, 800 resource groups, 5 minutes) then Ignore.
Exercises that depend on those edges say so in the README.

## 5. Curriculum

Each unit lists its goal, the AZ-104 domain and sub-heading it serves, prerequisites,
which skills are portal- or CLI-only, and a target exercise and drill count. Folder names
in this section are frozen. Exercise slugs inside a unit may be named when that unit is
authored, as long as composition (section 7.8) holds and the coverage matrix (section 5.3)
stays complete.

Work the units in order. A00 and A01 are the language and deployment foundation everything
else uses. A02 is the first live-lab unit: it deploys the course budget and action group,
and is a prerequisite for every later `[LAB]`.

### A00: Bicep language and structure

- **Folder:** `units/a00-bicep-language`
- **AZ-104:** Deploy and manage Azure compute resources → Automate deployment of resources
  by using ARM templates or Bicep files (interpret a Bicep file; modify an existing Bicep
  file). Also the language all later units use.
- **Goal:** After this unit the student can read a Bicep file, explain parameters,
  variables, resources, modules, outputs, and types, and write a small file that compiles
  and satisfies a structural test.
- **Portal / CLI-only:** none required.
- **Targets:** 7 exercises, 3 drills. Mix: WRITE, MODIFY, BUG, PREDICT, EXPLAIN.
- **Notes:** No live deploy. Cover `bicepconfig.json` and `bicep lint` here so later units
  can treat lint failures as real bugs.

### A01: Deployments, what-if, and ARM JSON

- **Folder:** `units/a01-deployments-and-arm`
- **AZ-104:** Automate deployment… (interpret an ARM template; modify an existing ARM
  template; deploy resources by using an ARM template or a Bicep file; export a deployment
  as an ARM template or compile a deployment as a Bicep file). Scopes and what-if.
- **Goal:** The student can place a deployment at resource-group, subscription, management
  group, or tenant scope; choose Incremental vs Complete; run validate and what-if against
  a **fixture**; read and modify ARM JSON; decompile ARM to Bicep and compile Bicep to
  ARM; say what is lost or rewritten in that round trip. Export and decompile in this
  unit are offline, from a fixture or a compiled template.
- **Portal / CLI-only:** none live. A checked-in export/decompile fixture covers the
  offline export bullet in this unit. The live export of a real deployment is in A02.
- **Targets:** 7 exercises, 2 drills. Must include `[MODIFY]` on ARM JSON, `[WHATIF]`
  (fixture), `[WRITE]` in Bicep, and an `[EXPLAIN]` on scope and mode.
- **Notes:** **A01 is offline only. There is no `[LAB]` in A01**, and there is no
  "return after A02" exercise in this unit. `arm-ttk` is optional on the ARM JSON
  exercises only. The first live deploy is in A02.

### A02: Cost control and lab guardrails

- **Folder:** `units/a02-cost-and-guardrails`
- **AZ-104:** Manage Azure subscriptions and governance → Manage costs by using alerts,
  budgets, and Azure Advisor recommendations. Also the course's own safety net.
- **Goal:** The student deploys a monthly budget with an action group, reads Advisor, tags
  lab resources so `lab-down` and the sweep can find them, and understands which course
  resources cost money if left running.
- **Portal / CLI-only:** reading Advisor recommendations; inspecting budget status in the
  portal or with CLI.
- **Targets:** 5 exercises, 2 drills. **Required `[LAB]` (`A02-e01`):** this is the
  course's **first live deploy**. The exercise ships an `up.ps1` that `lab-up` runs, and
  that script runs `az deployment sub create`. The template deploys a subscription-scope
  `Microsoft.Consumption/budgets@2024-08-01` named from `.lab-env.json` `budget.name`
  (default `lagb-monthly`), monthly, amount in the **$10–$25** range (`budget.amount`,
  default `25`), with five notifications (the per-budget maximum Azure allows):
  **Actual** 50/80/100% and **Forecasted** 80/100%, emailed to `budget.contactEmail`
  and an action group. The action group lives in a **persistent** resource group,
  `guardrails.resourceGroup` (default `lagb-guardrails`), tagged `course`,
  `unit=a02-cost-and-guardrails`, `exercise`, `lifecycle=persistent`, and `owner`,
  with **no** `expires`. `lab-down` skips that group unless `-IncludePersistent` is
  passed; `lab-sweep` lists it as expected, and it does not count toward exit 1.
  Authors may also include a SKU/region restrictive Policy, or a small A01-style
  template, in this or a later A02 exercise. Live export of the budget deployment
  uses `az deployment sub export` (ARM JSON or Bicep), so the official export bullet
  is covered as A01 offline compile/decompile plus A02 live export. This exercise is
  the gate for every later `[LAB]` (section 10.3).
- **Notes:** This is "unit 1" in the operational sense: the first subscription-backed work,
  placed immediately after the student can author a deployment offline, and before any
  unit that creates disks, public IPs, Bastion, or vaults. Isolation checks
  (`.lab-env.json`, `az account show`) are taught here and then enforced by `lab-up.ps1`.

### A03: Resource groups, tags, locks, subscriptions, and management groups

- **Folder:** `units/a03-resource-organization`
- **AZ-104:** Manage Azure subscriptions and governance → resource locks, tags, resource
  groups, subscriptions, management groups.
- **Goal:** Organise an estate: create and manage resource groups in Bicep at the right
  scope, apply tags (including the course tags from section 10), set CanNotDelete and
  ReadOnly locks, and explain subscription and management-group scope.
- **Portal / CLI-only:** managing subscriptions (billing/move/policy at subscription
  scope) as `[CLI]` / `[EXPLAIN]`; management groups if the learner tenant allows them,
  otherwise `[EXPLAIN]` plus a read-only `[CLI]` (default retained, section 13.3).
- **Targets:** 6 exercises, 2 drills.

### A04: Azure Policy and role-based access

- **Folder:** `units/a04-policy-and-rbac`
- **AZ-104:** Implement and manage Azure Policy; Manage access to Azure resources (built-in
  roles, assign roles at different scopes, interpret access assignments).
- **Goal:** Assign built-in Policy definitions (and a small custom one if needed for the
  lab SKU/region guard), assign built-in roles at RG, subscription, and (if available)
  management-group scope in Bicep, and interpret an access assignment in the portal or CLI.
- **Portal / CLI-only:** interpret access assignments; confirm a Policy effect in the
  portal after a `[LAB]`.
- **Targets:** 6 exercises, 2 drills. At least one `[BUG]` (for example a role assignment
  at the wrong scope, or a Policy that does not apply).

### A05: Microsoft Entra users, groups, and directory access

- **Folder:** `units/a05-entra-identity`
- **AZ-104:** Manage Microsoft Entra users and groups (create users and groups; manage
  properties; licences; external users; SSPR). Complements A04 on access.
- **Goal:** Perform the directory tasks the exam measures in the **dedicated disposable
  Entra ID test tenant** (section 3.2), and explain how Entra identity is not the same as
  an Azure RBAC assignment.
- **Portal / CLI-only:** **almost the entire unit.** Bicep has no honest way to grade
  "configure SSPR." Exercises are `[PORTAL]` / `[CLI]` / `[EXPLAIN]`, with query scripts
  (`az ad user`, Microsoft Graph via `az` or Microsoft.Graph) and `ANSWER.md`.
- **Targets:** 6 exercises, 2 drills. Drills are CLI/PowerShell-script drills (section
  4.2), not Bicep.
- **Composition (this is the rule, not a loosening):** no required `[BUG]` or
  `[WHATIF]`. At least one `[PREDICT]` against a CLI fixture is allowed and satisfies
  the predict slot. At least one `[PORTAL]` or `[CLI]`. `[WRITE]` / `[MODIFY]` are not
  required; include them only if a slice is genuinely Bicep-able (for example a role
  assignment).
- **Notes:** No exercises that modify production or work users, or users in the personal
  MSA Default Directory. Directory scripts and `lab-up` for this unit refuse to run
  unless the active tenant matches `expectedEntraTenantId` (section 3.2). The lesson
  states the tenant rule, how to switch directories, and Free vs P1/P2 (including the
  30-day trial warning) before the first task. Free-tier tasks are the default path;
  dynamic groups, Conditional Access, SSPR reset, and PIM are clearly marked and use a
  trial in the *test* tenant or an `[EXPLAIN]` / Learn sandbox alternative.

### A06: Storage accounts, redundancy, and encryption

- **Folder:** `units/a06-storage-accounts`
- **AZ-104:** Configure and manage storage accounts (create and configure; redundancy;
  object replication; encryption).
- **Goal:** Author a storage account in Bicep with a chosen SKU and redundancy, encryption
  settings, and (as a later exercise) object replication, all checked structurally and,
  optionally, with a low-cost `[LAB]`.
- **Portal / CLI-only:** none required here (Explorer/AzCopy wait until A08).
- **Targets:** 6 exercises, 2 drills.

### A07: Storage access, SAS, keys, and IP firewalls

- **Folder:** `units/a07-storage-access`
- **AZ-104:** Configure access to storage — the A07 slice is **IP firewall rules, SAS
  tokens, stored access policies, and access keys**. This unit does **not** depend on
  VNets (A09) or Azure Files (A08). The official bullet "Configure Azure Storage
  firewalls and virtual networks" (VNet rules / service endpoints on a storage account)
  is taught in **A10**. "Configure identity-based access for Azure Files" is taught in
  **A08**, after the file share is created.
- **Goal:** Restrict a storage account with **IP** firewall rules, express a stored
  access policy in the template or CLI, and *create and use* a SAS and rotate or list
  keys from the CLI.
- **Portal / CLI-only:** creating and using SAS tokens; managing access keys. IP
  firewall rules can be Bicep, with a `[CLI]` confirmation.
- **Targets:** 6 exercises, 2 drills.
- **Notes:** PSRule Security L1 includes `Azure.Storage.LocalAuth`, which wants shared-key
  / local authentication disabled. A07 teaches SAS, stored access policies, and access
  keys, which use that mechanism. Whether those exercises need a documented
  suppression is a pending question (section 4.5); do not invent one in the unit
  until it is decided.

### A08: Azure Files and Blob Storage

- **Folder:** `units/a08-storage-data-services`
- **AZ-104:** Configure Azure Files and Azure Blob Storage (file share; blob container;
  tiers; snapshots and soft delete for Azure Files; blob lifecycle; blob versioning).
  Also: manage data by using Azure Storage Explorer and AzCopy; and **configure
  identity-based access for Azure Files** (moved here from the access unit so it comes
  after the share exists).
- **Goal:** Declare shares and containers, tiers, soft delete, versioning, and a lifecycle
  rule in Bicep; configure identity-based access for Azure Files **after** the file share
  is created; move a sample object with AzCopy; look at the same account in Storage
  Explorer.
- **Portal / CLI-only:** Storage Explorer and AzCopy (`[PORTAL]` / `[CLI]`); confirm
  identity-based Files access with `[CLI]` as needed.
- **Targets:** 6 exercises, 2 drills.

### A09: Virtual networks, peering, addresses, and routing

- **Folder:** `units/a09-virtual-networks`
- **AZ-104:** Configure and manage virtual networks in Azure (VNets and subnets; peering;
  public IP addresses; user-defined routes; troubleshoot network connectivity).
- **Goal:** Build VNets and subnets, peer them, attach a public IP only when the exercise
  requires it, add a UDR, and troubleshoot connectivity with the tools A15 will deepen.
- **Portal / CLI-only:** troubleshooting connectivity (`[CLI]` / `[PORTAL]`; Network
  Watcher is taught in A15 but a first `az network watcher` or effective-route look can
  live here).
- **Targets:** 6 exercises, 2 drills.
- **Notes:** Public IPs are created only in named exercises and are tagged for `lab-down`.
  Prefer no public IP when a private-only topology will do.

### A10: Network security groups, Bastion, and private access

- **Folder:** `units/a10-network-security`
- **AZ-104:** Configure secure access to virtual networks (NSGs and ASGs; evaluate
  effective security rules; Azure Bastion; service endpoints; private endpoints). Also
  the official bullet **Configure Azure Storage firewalls and virtual networks** (VNet
  rules / service endpoints on a storage account), taught here because it needs a VNet
  and sits with the other private-access work.
- **Goal:** Write NSGs and ASGs in Bicep, evaluate effective rules from the CLI or portal,
  configure service and private endpoints (including storage-account VNet rules / service
  endpoints), and know when Bastion is the right access path and what it costs.
- **Portal / CLI-only:** evaluate effective security rules.
- **Optional costly `[LAB]`:** Azure Bastion. Prefer the **Developer** SKU (free) when it
  covers the skill. Basic and Standard are optional "see the bill, then delete" labs,
  each with `up.bicep` and `lab-up` / `lab-down` (section 10.7). Leaving Basic or
  Standard running is a monthly bill in the $140–$220 range plus the public IP.
- **Targets:** 6 exercises, 2 drills.

### A11: Azure DNS and load balancing

- **Folder:** `units/a11-dns-and-load-balancing`
- **AZ-104:** Configure name resolution and load balancing (Azure DNS; internal or public
  load balancer; troubleshoot load balancing).
- **Goal:** Configure Azure DNS (public and/or private zones) and an internal or public
  load balancer in Bicep, and troubleshoot a broken probe or rule.
- **Portal / CLI-only:** troubleshoot load balancing.
- **Optional costly `[LAB]`:** a public DNS zone and a Standard public Load Balancer
  (rules + public IP) each get `up.bicep` and same-day teardown (section 10.7). A
  private DNS zone or an internal load balancer is the cheaper default path. Learners
  can create a public zone **without** registrar delegation (section 5, A14 alternative
  path) just to practice records.
- **Targets:** 5 exercises, 2 drills.

### A12: Virtual machines, disks, and scale sets

- **Folder:** `units/a12-virtual-machines`
- **AZ-104:** Create and configure virtual machines (create a VM; Azure Disk Encryption;
  move a VM to another RG, subscription, or region; manage sizes; manage disks;
  availability zones and sets; VM scale sets).
- **Goal:** Deploy a small VM and a scale set in Bicep (B-series or whatever the lab
  Policy allows), attach and resize disks, express zone or availability-set placement,
  explain Disk Encryption, and *move* a VM with the portal or CLI.
- **Portal / CLI-only:** move a VM to another resource group, subscription, or region.
  Azure Disk Encryption is an **optional** costly `[LAB]` (ADE itself is free; you pay
  for the small VM, managed disk, Key Vault Standard operations, and any public IP)
  with `up.bicep` and `lab-up` / `lab-down` (section 10.7). The bullet is always
  covered, at least as `[EXPLAIN]`, if the student skips the live lab.
- **Targets:** 7 exercises, 2 drills. Do not raise this target. The author (Jack) may
  combine official bullets into fewer exercises, provided every official AZ-104 bullet
  remains in the section 5.3 coverage matrix and the unit still meets composition
  minimums (section 7.8).
- **Notes:** Auto-shutdown is mandatory on every lab VM (section 10). `lab-down` after
  each `[LAB]`. No VPN gateway, no Azure Firewall, no D-series "to be safe."

### A13: Container Registry, Instances, and Apps

- **Folder:** `units/a13-containers`
- **AZ-104:** Provision and manage containers in the Azure portal (ACR; ACI; Azure
  Container Apps; sizing and scaling for ACI and Container Apps).
- **Goal:** Create and use a registry, provision a container with ACI and with Container
  Apps, and scale or size them. Bicep covers the resources; the exam names "in the Azure
  portal," so the unit also has a portal walkthrough.
- **Portal / CLI-only:** the portal provisioning and scaling path the sub-heading names;
  Bicep is still required so the student can see both.
- **Optional costly `[LAB]`:** ACR Basic, ACI, and Container Apps Consumption each get
  `up.bicep` and same-day teardown (section 10.7). Prefer Container Apps Consumption
  inside the monthly free grant; tear down an ACR the same day (it has a daily meter).
- **Targets:** 6 exercises, 2 drills.

### A14: Azure App Service

- **Folder:** `units/a14-app-service`
- **AZ-104:** Create and configure Azure App Service (plan; plan scaling; create an App
  Service; certificates and TLS; map an existing custom DNS name; backup; networking
  settings; deployment slots).
- **Goal:** Provision a plan and an app, configure TLS, slots, backup, and networking in
  Bicep, scale the plan, and map a custom DNS name when following the live path below.
- **Custom DNS (Nathan's path):** use a **subdomain of `skopekreep.com`**, for example
  `az104-lab.skopekreep.com`, so records at the root of `skopekreep.com` are not
  disrupted. Map that name to the App Service and, when the plan allows it, bind an
  App Service managed certificate.
- **Alternative path (learners with no domain):** complete the app, TLS-on-the-default-
  host, backup, networking, and scaling work on the built-in `*.azurewebsites.net`
  name; walk through an Azure DNS public zone **without** delegating a registrar (you
  can still create records and see them in the portal; the internet will not resolve
  the zone until NS records are delegated); and, optionally, buy a cheap domain at a
  third-party registrar (Azure DNS does not sell domains) if they want a live mapping.
  Official DNS FAQ: <https://azure.microsoft.com/en-us/pricing/details/dns/>.
- **SKU notes:** F1 Free is $0 but does not support custom-domain TLS or deployment
  slots. **B1 Basic** supports a custom domain and a managed certificate (SNI).
  **Deployment slots require S1 Standard** (or higher). Slots and custom-domain TLS
  are **optional** costly labs with `up.bicep` and same-day teardown (section 10.7).
- **Portal / CLI-only:** the live DNS mapping and certificate bind (or the no-domain
  walkthrough).
- **Targets:** 7 exercises, 2 drills. Do not raise this target. The author (Jack) may
  combine official bullets into fewer exercises, provided every official AZ-104 bullet
  remains in the section 5.3 coverage matrix and the unit still meets composition
  minimums (section 7.8).
- **Notes:** Prefer a Free or Linux Basic plan allowed by the lab Policy unless the
  exercise needs slots. Tear down apps and plans in `lab-down`; an empty plan still
  bills on paid SKUs.

### A15: Azure Monitor, Insights, and Network Watcher

- **Folder:** `units/a15-monitor`
- **AZ-104:** Monitor resources in Azure (interpret metrics; log settings; query and
  analyse logs; alert rules, action groups, and alert processing rules; Insights for VMs,
  storage accounts, and networks; Network Watcher and Connection Monitor).
- **Goal:** Emit diagnostic settings from Bicep, write an alert rule and an action group,
  run a KQL query, read a metric chart, and use Network Watcher / Connection Monitor on a
  lab network from earlier units.
- **Portal / CLI-only:** interpret metrics; Insights; Network Watcher and Connection
  Monitor; ad-hoc KQL over live logs. Diagnostic settings, alert rules, and action groups
  are Bicep-first. A small Log Analytics workspace is fine inside the **first 5
  GB/month free** Analytics Logs grant; ingestion beyond that is an **optional**
  costly path (section 10.7). Tear the workspace down when the unit is finished.
- **Targets:** 6 exercises, 2 drills.

### A16: Backup and Site Recovery

- **Folder:** `units/a16-backup-and-recovery`
- **AZ-104:** Implement backup and recovery (Recovery Services vault; Azure Backup vault;
  backup policy; backup and restore operations; Site Recovery for Azure resources;
  failover to a secondary region; reports and alerts for backups).
- **Goal:** Declare both vault kinds and a backup policy in Bicep, perform a backup and a
  restore of a cheap resource, and explain (or, if opted in, rehearse) Azure Site Recovery
  and a failover.
- **Portal / CLI-only:** backup and restore operations; ASR configuration and failover;
  backup reports and alerts. Vaults and policies can still be Bicep.
- **Optional costly `[LAB]`:** Recovery Services vault + Azure Backup (protected instance
  + LRS storage) and Azure Site Recovery (replication + optional test failover) each get
  `up.bicep` and `lab-up` / `lab-down` with **soft-delete purge warnings** (section 10.7).
  Backup instance fees are **monthly**, not hourly. ASR instance fees are free for the
  first 31 days, but storage, egress, and failover compute still cost, and day 32 starts
  a $25/month instance fee if protection is left on. The default path is `[EXPLAIN]`
  plus a Microsoft Learn sandbox; the live labs are opt-in and same-day.
- **Targets:** 6 exercises, 2 drills.
- **Notes:** Do not leave a vault, a protected instance, or replication behind.

### A17: Exam readiness

- **Folder:** `units/a17-exam-readiness`
- **AZ-104:** the whole outline, as a review.
- **Goal:** The student works Microsoft's practice assessment, walks the official study
  guide bullet by bullet against this course's coverage matrix, and fills any personal
  gaps before booking.
- **Portal / CLI-only:** practice assessment and portal walkthroughs are the work.
- **Targets:** 4 exercises, 0–1 drills. **Composition (this is the rule, not a
  loosening):** no required `[WRITE]`, `[MODIFY]`, `[BUG]`, or `[WHATIF]`. The unit is
  `[PREDICT]`, `[EXPLAIN]`, `[PORTAL]` / `[CLI]` walkthroughs, and practice-assessment
  work. No new billable resources.
- **Tenants:** Entra walkthroughs in A17 use the **A05 test tenant** (and the
  `expectedEntraTenantId` refusal). Everything else in A17 uses the personal
  subscription. If the student has already deleted the test tenant, A17 Entra review is
  a Microsoft Learn sandbox and `[EXPLAIN]` only.
- **Official links to cite in the lesson and READMEs (re-check at authoring time):**
  - Study guide: <https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104>
  - Certification page: <https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/>
  - Practice assessment: the certification page's current "Practice Assessment" / AI
    Skills Navigator entry, and the legacy `https://aka.ms/AZ104-LearnPA` only if Microsoft
    still hosts it (as of 20 November 2026 the study guide already recommended the new
    experience and said the Learn legacy assessment was no longer being updated).
  - Exam sandbox, scoring (700), duration (100 minutes), renewal (12 months).

### Capstones

Each capstone lives at `capstones/cN-<name>/` with a unit-level `LESSON.md` or README
and one or more `eNN-<slug>/` exercise folders that use the **same format as unit
exercises** (section 7). A capstone is typically one L exercise (modules allowed inside
that folder); additional `eNN` folders are allowed if they earn their keep. Same harness
rules; `[LAB]` is optional and always torn down. Solutions are complete and pass
offline verify.

**When to attempt them:** **C1 after A04**, **C2 after A11**, **C3 after A16**.

- **C1: `capstones/c1-landing-zone` — Governance baseline.** Attempt after A04. A small
  subscription or resource-group baseline: management organisation, tags, locks, Policy,
  RBAC, and the course budget pattern. Pulls A02–A04 (and A05 only as documentation of
  where identity sits).
- **C2: `capstones/c2-hub-spoke` — Hub-and-spoke network.** Attempt after A11. Shared
  hub, two spokes, peering, NSGs, optional Bastion (Developer preferred; Basic/Standard
  optional and torn down the same day) or a cheaper alternative, DNS. Pulls A09–A11.
  Cost rules still apply: no Firewall/VPN unless a future decision adds a tightly
  scoped, immediately deleted `[LAB]`.
- **C3: `capstones/c3-three-tier` — App, monitoring, and backup.** Attempt after A16. A
  small three-tier (or two-tier, if a VM tier would blow the budget) application:
  network, compute or App Service, storage, Monitor alerts, and a backup policy. Pulls
  A06–A08, A12 or A14, A15, A16.

### Totals

| Kind | Count (target) |
|---|---|
| Units | 18 (`A00`–`A17`) |
| Capstones | 3 |
| Exercises (units, excluding drills) | about 108 |
| Drills | about 36 |
| Estimated `[LAB]` exercises | a minority; every one gated by A02 and torn down |

Phase 2 may move an exercise across adjacent units if the coverage matrix remains
complete and composition still holds. It may not drop an official AZ-104 bullet.
### 5.3 Coverage matrix

Every official task bullet from the 20 November 2026 study-guide fetch. "Primary" is the
unit that teaches it; capstones reuse but do not replace that unit.

**Manage Azure identities and governance (20–25%)**

| Official bullet | Primary unit | How (IaC, portal/CLI, or both) |
|---|---|---|
| Create users and groups | A05 | `[PORTAL]` / `[CLI]` |
| Manage user and group properties | A05 | `[PORTAL]` / `[CLI]` |
| Manage licenses in Microsoft Entra ID | A05 | `[PORTAL]` / `[CLI]` |
| Manage external users | A05 | `[PORTAL]` / `[CLI]` |
| Configure self-service password reset (SSPR) | A05 | `[PORTAL]` / `[EXPLAIN]` |
| Manage built-in Azure roles | A04 | Bicep role assignments + `[EXPLAIN]` |
| Assign roles at different scopes | A04 | Bicep + `[LAB]` / `[CLI]` confirm |
| Interpret access assignments | A04, A05 | `[PORTAL]` / `[CLI]` |
| Implement and manage Azure Policy | A04 | Bicep + `[LAB]` confirm |
| Configure resource locks | A03 | Bicep `[WRITE]` / `[BUG]` |
| Apply and manage tags on resources | A03 | Bicep; course tags required |
| Manage resource groups | A03 | Bicep at subscription scope |
| Manage subscriptions | A03 | `[CLI]` / `[EXPLAIN]` |
| Manage costs by using alerts, budgets, and Azure Advisor recommendations | A02 | Bicep budget + action group `[LAB]`; Advisor `[PORTAL]` / `[CLI]` |
| Configure management groups | A03 | Bicep if the personal tenant allows it; otherwise `[EXPLAIN]` / `[CLI]` (section 13.3) |

**Implement and manage storage (15–20%)**

| Official bullet | Primary unit | How |
|---|---|---|
| Configure Azure Storage firewalls and virtual networks | A10 | Bicep (VNet rules / service endpoints on a storage account, with the other private-access work); confirm with `[CLI]` |
| Create and use shared access signature (SAS) tokens | A07 | `[CLI]` (tokens are runtime) |
| Configure stored access policies | A07 | Bicep and/or `[CLI]` |
| Manage access keys | A07 | `[CLI]` |
| Configure identity-based access for Azure Files | A08 | Bicep + `[CLI]`, after the file share is created |
| Create and configure storage accounts | A06 | Bicep `[WRITE]` |
| Configure Azure Storage redundancy | A06 | Bicep `[MODIFY]` / `[PREDICT]` |
| Configure object replication | A06 | Bicep and/or `[CLI]` |
| Configure storage account encryption | A06 | Bicep |
| Manage data by using Azure Storage Explorer and AzCopy | A08 | `[PORTAL]` / `[CLI]` |
| Create and configure a file share in Azure Storage | A08 | Bicep |
| Create and configure a container in Blob Storage | A08 | Bicep |
| Configure storage tiers | A08 | Bicep `[MODIFY]` |
| Configure snapshots and soft delete for Azure Files | A08 | Bicep |
| Configure blob lifecycle management | A08 | Bicep |
| Configure blob versioning | A08 | Bicep |

**Deploy and manage Azure compute resources (20–25%)**

| Official bullet | Primary unit | How |
|---|---|---|
| Interpret an ARM template or a Bicep file | A00, A01 | `[EXPLAIN]` / `[PREDICT]` / `[MODIFY]` |
| Modify an existing ARM template | A01 | `[MODIFY]` on ARM JSON |
| Modify an existing Bicep file | A00, A01 | `[MODIFY]` |
| Deploy resources by using an ARM template or a Bicep file | A02 (first live), later `[LAB]`s | A01 is offline only (author, validate, what-if fixture). First live deploy is the A02 budget / action-group `[LAB]`, which may include a small A01-style template |
| Export a deployment as an ARM template or compile a deployment as a Bicep file | A01, A02 | A01: offline `bicep build` / decompile from a fixture or a compiled template. A02: live export of the budget-lab subscription deployment with `az deployment sub export` |
| Create a virtual machine | A12 | Bicep `[WRITE]` + optional `[LAB]` |
| Configure Azure Disk Encryption | A12 | Bicep and/or `[EXPLAIN]` / `[LAB]` |
| Move a virtual machine to another resource group, subscription, or region | A12 | `[CLI]` / `[PORTAL]` `[LAB]` |
| Manage virtual machine sizes | A12 | Bicep `[MODIFY]` + `[CLI]` |
| Manage virtual machine disks | A12 | Bicep |
| Deploy virtual machines to availability zones and availability sets | A12 | Bicep `[WRITE]` / `[PREDICT]` |
| Deploy and configure an Azure Virtual Machine Scale Sets | A12 | Bicep |
| Create and manage an Azure container registry | A13 | Bicep + `[PORTAL]` |
| Provision a container by using Azure Container Instances | A13 | Bicep + `[PORTAL]` |
| Provision a container by using Azure Container Apps | A13 | Bicep + `[PORTAL]` |
| Manage sizing and scaling for containers, including Azure Container Instances and Azure Container Apps | A13 | Bicep + `[PORTAL]` |
| Provision an App Service plan | A14 | Bicep |
| Configure scaling for an App Service plan | A14 | Bicep / `[CLI]` |
| Create an App Service | A14 | Bicep `[WRITE]` |
| Configure certificates and TLS for an App Service | A14 | Bicep and/or `[PORTAL]` |
| Map an existing custom DNS name to an App Service | A14 | Live path: subdomain of `skopekreep.com` (e.g. `az104-lab.skopekreep.com`). Alternative: `*.azurewebsites.net` + optional undelegated Azure DNS zone |
| Configure backup for an App Service | A14 | Bicep |
| Configure networking settings for an App Service | A14 | Bicep |
| Configure deployment slots for an App Service | A14 | Bicep |

**Implement and manage virtual networking (15–20%)**

| Official bullet | Primary unit | How |
|---|---|---|
| Create and configure virtual networks and subnets | A09 | Bicep `[WRITE]` |
| Create and configure virtual network peering | A09 | Bicep |
| Configure public IP addresses | A09 | Bicep; cost-tagged |
| Configure user-defined network routes | A09 | Bicep |
| Troubleshoot network connectivity | A09, A15 | `[CLI]` / `[PORTAL]` |
| Create and configure network security groups (NSGs) and application security groups | A10 | Bicep |
| Evaluate effective security rules in NSGs | A10 | `[CLI]` / `[PORTAL]` |
| Implement Azure Bastion | A10 | **Optional** guarded `[LAB]` (`up.bicep`, prefer Developer SKU) or `[EXPLAIN]` + what-if |
| Configure service endpoints for Azure platform as a service (PaaS) | A10 | Bicep |
| Configure private endpoints for Azure PaaS | A10 | Bicep |
| Configure Azure DNS | A11 | Bicep |
| Configure an internal or public load balancer | A11 | Bicep |
| Troubleshoot load balancing | A11 | `[CLI]` / `[PORTAL]` |

**Monitor and maintain Azure resources (10–15%)**

| Official bullet | Primary unit | How |
|---|---|---|
| Interpret metrics in Azure Monitor | A15 | `[PORTAL]` / `[EXPLAIN]` |
| Configure log settings in Azure Monitor | A15 | Bicep diagnostic settings |
| Query and analyze logs in Azure Monitor | A15 | `[CLI]` / `[EXPLAIN]` (KQL) |
| Set up alert rules, action groups, and alert processing rules in Azure Monitor | A15 | Bicep (A02 already used an action group) |
| Configure and interpret monitoring of virtual machines, storage accounts, and networks by using Azure Monitor Insights | A15 | `[PORTAL]` + Bicep where Insights has a resource |
| Use Azure Network Watcher and Connection Monitor | A15 | `[PORTAL]` / `[CLI]` |
| Create a Recovery Services vault | A16 | Bicep; teardown documented |
| Create an Azure Backup vault | A16 | Bicep |
| Create and configure a backup policy | A16 | Bicep |
| Perform backup and restore operations by using Azure Backup | A16 | `[LAB]` / `[PORTAL]` |
| Configure Azure Site Recovery for Azure resources | A16 | `[EXPLAIN]` and/or **optional** scoped `[LAB]` (`up.bicep`, section 10.7) |
| Perform a failover to a secondary region by using Site Recovery | A16 | `[EXPLAIN]` and/or **optional** scoped `[LAB]` (`up.bicep`, section 10.7) |
| Configure and interpret reports and alerts for backups | A16 | `[PORTAL]` / `[CLI]` |

Audience-profile tools (PowerShell, Azure CLI, the portal, ARM templates or Bicep, Microsoft
Entra ID) are used throughout, not in a single exercise.

## 6. Repository layout

Mirrors `LearnCDataStructuresByGrinding`, with PowerShell and Bicep in place of `common.mk`
and C. Specs live in `docs/`.

```
LearnAzureByGrinding/
├── README.md                 course front page and course map (Monk, Phase 2)
├── PROGRESS.md               student ledger (Monk, Phase 2)
├── bicepconfig.json          linter settings for the whole repo
├── ps-rule.yaml              PSRule.Rules.Azure, including Bicep expansion
├── .gitignore
├── .lab-env.example.json  copy to gitignored `.lab-env.json`
├── .github/workflows/ci.yml
├── docs/
│   ├── SPEC.md               this file
│   ├── AUTHORING.md          content rules for authors (Phase 1)
│   ├── AUTHORING-INFRA.md    harness, pins, and script mechanics (Phase 1)
│   ├── ROADMAP.md            student-facing learning path (Monk, Phase 2)
│   └── review/<name>.md      each author's technical-doubt log
├── scripts/
│   ├── toolchain.psd1        single source of toolchain pins
│   ├── install-tools.ps1     install or check the pins (`-CheckOnly`; CI uses `-Ci`)
│   ├── verify-all.ps1        every starter and solution (offline)
│   ├── check.ps1             student-facing: is *my* work in this folder done?
│   ├── lint.ps1              structure, pins, bicepconfig, portability
│   ├── psrule.ps1            PSRule over solutions and lesson-demos (must be clean)
│   ├── selftest.ps1          tests of the harness itself
│   ├── rep.ps1               fresh copy of a drill or exercise into reps/
│   └── lab/                  lab-up.ps1, lab-down.ps1, lab-sweep.ps1 (live Azure only)
├── lib/
│   ├── AzGrinding.psd1 / .psm1    shared Pester helpers, assert conventions, id printing
│   └── templates/            author-only skeletons (exercise.psd1, write/modify/cli-drill tests;
│                             A02 subscription-scope `up.sub-scope.ps1` / `.bicep` / action-group)
├── units/aNN-<slug>/         LESSON.md, eNN-<slug>/, drills/rNN-<slug>/, lesson-demo/
├── capstones/cN-<name>/     LESSON.md or README, eNN-<slug>/ (same format as units)
└── solutions/                mirrors units/ (including drills/) and capstones/
```

No README, lesson, or exercise file links to `solutions/`. Build artefacts (`out/`,
compiled `*.json` next to a `.bicep` unless the exercise ships a fixture, `reps/`,
`.psrule/`, Pester test results) are gitignored. The local pin file `.lab-env.json`
and `*.local.bicepparam` are gitignored and must never be committed. verify-all and
local scripts write under a temp directory or a gitignored `out/`, then clean it.
Optional costly labs add an `up.bicep` in the exercise folder (section 10.7).
`A02-e01` ships an `up.ps1` that runs `az deployment sub create` (section 10.3).
Those files are authored with the unit, not in this spec-only drop.

This Phase 1 drop is **the spec and a short README only.** The other paths are named here
so Phase 1 infra and Phase 2 authors share one layout. They are not created in this drop.

## 7. File formats

### 7.1 LESSON.md

The usual range is 120–250 lines. The **default cap is 300 lines**. A01, A05, A12,
A14, and A16 may go to **450 lines**; the lesson (or its AUTHORING entry) must include
a one-line note that the exception was used. Do not raise the default, and do not
allow a silent overrun of 300 (or of 450 on an excepted unit). Longer than the cap
that applies is a signal to split. Sections, in this order (headings exactly as
written):

```markdown
# ANN: Title

## Advance organizer
What the unit is for, what changes in the reader's thinking, what they must already know
(by unit id), and a short "after this unit you can" list.

## Foundations
### <named sections>      as many as needed; contrasts in tables with every cell filled

## Worked example: <title>
One or two. Reasoning shown step by step, and at least one
**The plausible wrong reading.** paragraph: what a competent reader would conclude, and why
it is wrong. Neighbouring problems only: never an exercise's solution.

## Distinctions worth keeping straight
| Confusion | What separates them |

## Official docs
Exact Microsoft Learn pages (and `az` / PowerShell command pages) that exist today; re-check
URLs when the unit is authored. Official docs are **reference, not the reading.** The
lesson is the reading; the links are where a student goes to confirm or go deeper.

## Check yourself
3–5 production questions, answers in one <details> block.

## Takeaways
3–6 single-sentence claims that could be disagreed with.

## Exercises
| # | Folder | Tag | Size | What |

## Drills
| # | Folder | Skill |
```

Do not solve an exercise in the lesson. Never invent tool or portal output; quote only
from `capture*.txt` or `lesson-demo/` produced from the shipped source. If a capture is
not yet taken, the lesson defers it in prose and must not use the `OUTPUT-PENDING` token.
That token belongs in the exercise or drill fixture / capture file, where lint and
verify-all fail and merge is blocked until real output replaces it.

### 7.2 Exercise README.md

```markdown
# aNN-eNN-<slug> `[TAG]` (SIZE)

## Goal
What to build, change, fix, predict, explain, or do in the portal/CLI.

> **This starter is supposed to fail its tests, on purpose.** ...
  (WRITE / DRILL / MODIFY: the verbatim notice in section 7.5)

## Constraints
Concrete and testable ("the compiled template contains one
Microsoft.Storage/storageAccounts with supportsHttpsTrafficOnly true"; "lab-down removes
the resource group"; "ANSWER.md names the two change types").

## Verify
Students run `scripts/check.ps1` from the exercise or drill folder (or on a `reps/`
copy) to ask whether *their* work is done. `verify-all` is the author and CI command:
it expects an untouched starter to **fail**, so it is the wrong default for a student
who has just started writing. Lab exercises also name `scripts/lab/lab-up.ps1` and
`scripts/lab/lab-down.ps1`. Depths:

- from `units/aNN-<slug>/eNN-<slug>/`: `pwsh -File ../../../scripts/check.ps1`
- from `units/aNN-<slug>/drills/rNN-<slug>/`: `pwsh -File ../../../../scripts/check.ps1`
- from `capstones/cN-<name>/eNN-<slug>/`: `pwsh -File ../../../scripts/check.ps1`
  (capstones use `eNN` folders under the capstone, the same layout as units; do not
  place the exercise files at the capstone root.)
- Authors and CI still call `scripts/verify-all.ps1` (with `-Only <path>` when
  narrowing) and, for live labs, `scripts/lab/lab-up.ps1` / `lab-down.ps1`.
```

- State the **goal**, the **constraints**, and **how to verify**. Never a step list that
  dictates the implementation of a `[WRITE]`.
- At most **one** hint, in a collapsed `<details>` block. Drills have no hint.
- `[BUG]` READMEs ask for `ANSWER.md`: what was wrong, the mechanism, and which tool
  (lint rule, PSRule rule, Pester assertion, portal blade) showed it. A bug exercise
  contains exactly the advertised defects; a second author confirms.
- `[LAB]` READMEs state the expected cost class, the teardown command, and that A02's
  budget must already be in place.
- When the exercise requires `ANSWER.md`, the README lists the required headings
  (and `exercise.psd1` repeats them in `AnswerHeadings`). verify-all fails if the
  file is missing, is empty or whitespace-only, or is missing any of those headings.
  CI does not grade the quality of the prose. A shipped solution `ANSWER.md`, if any,
  is a model answer, not a hash the student must match.

### 7.3 Drill README.md

```markdown
# aNN-rNN-<slug> `[DRILL]` (XS|S)

## Skill            what becomes automatic, and where it comes back later
## Rules            fresh copy via scripts/rep.ps1; what may be consulted; no live Azure
## Target           time per rep, number of reps (3+ on different days)
## Verify           the structural tests, via scripts/check.ps1 or Invoke-Pester
```

The unit-level `units/aNN-<slug>/drills/README.md` is a different file, and Monk owns
it. It is not a lesson. It states the short purpose of the drill set, how to use
`scripts/rep.ps1`, that there are no hints, and a list of `rNN-<slug>` entries with
one-line goals.

### 7.4 `exercise.psd1` (exercise, drill, and solution: identical except where a tag allows)

Every exercise, drill, and solution directory has a small manifest:

```powershell
@{
    Tags              = @('WRITE')      # first tag is primary; modifiers e.g. @('WRITE', 'LAB')
                                        # a drill is always Tags = @('DRILL')
    Entry             = 'main.bicep'    # or azuredeploy.json, or main.ps1 for a CLI drill
    Test              = 'main.tests.ps1'
    StudentRegion     = 'below-marker'  # below-marker | above-marker | whole-file
    ExpectResources   = @('Microsoft.Storage/storageAccounts')  # [WRITE]: types that must appear
    ExpectOutputs     = @('storageAccountName')                 # optional
    ExpectProperties  = @(
        @{ ResourceType = 'Microsoft.Storage/storageAccounts'; Path = 'sku.name'; Value = 'Standard_GRS' }
    )                                   # [MODIFY]: the starter already has the type
    ExpectDiagnostics = @()             # [BUG]: exact lint or PSRule rule ids the starter may fail
    AnswerHeadings    = @()             # required ANSWER.md headings, if any
}
```

The solution's `exercise.psd1` is byte-identical to the starter's (it is harness). Relative
paths to `lib/` and the repo-root `bicepconfig.json` are resolved from the course root,
which scripts detect by walking up to `lib/AzGrinding.psd1` (and `bicepconfig.json`
for script entry points). That works in selftest temp trees and in `reps/` without
copying this SPEC.

### 7.5 Starter sources

- `main.bicep` (or the ARM JSON entry) is the student-facing template. The Pester file
  `main.tests.ps1` is the harness: it compiles the entry, asserts structure, and on
  success prints `<id>: all checks passed`.
- The student writes below a marker line in the Bicep (or ARM JSON) file:

  `// ---- Your resources go below this line. ----`

  (ARM JSON exercises use a `"_comment": "---- Your resources go below this line. ----"`
  in a documented place, or a sibling `resources.json` the template references — Phase 1
  infra picks one convention and `AUTHORING-INFRA.md` states it.)
- `StudentRegion` on the manifest is `'below-marker'`, `'above-marker'`, or
  `'whole-file'`. The default is `'below-marker'`: the student writes below the shipped
  marker comment. `'above-marker'` is the named field for the documented exception
  where the student edits the template *above* a shipped test or harness region (for
  example a `[BUG]` or some `[MODIFY]` / `[PORTAL]` work whose defect lives there).
  `'whole-file'` is for `ANSWER.md`-only work or full-file edits. Harness byte-identity
  compares files outside the student region as defined by this field. Files that are
  never in the student region (`main.tests.ps1`, `exercise.psd1`, shipped parameter
  files, fixtures) stay byte-identical in the solution.
- The notice, verbatim, in every WRITE / DRILL / MODIFY README:

  > **This starter is supposed to fail its tests, on purpose.** A Bicep or ARM starter
  > is valid and it compiles. A CLI/PowerShell drill starter is valid PowerShell and
  > it parses. The resources, property changes, or commands you must write are not
  > there yet, so the tests fail. There are no placeholder resources, and nothing to
  > uncomment or delete to make the tests pass.

### 7.6 Solutions

`solutions/<mirror path>/`: every starter file, completed, plus `NOTES.md` with four
parts: **Why it is correct**, numbers or SKUs where relevant, **Alternatives**, **The
usual mistake**. No README links to solutions. For `[EXPLAIN]` / `[PREDICT]`, NOTES.md
is the reference answer; the template may be unchanged.

### 7.7 Exit codes

`0` pass; `1` a check failed (Pester, lint, PSRule, or verify-all); `2` usage or missing
toolchain; `3` a `[LAB]` declined or blocked (cost-guard missing, no login, corporate-tenant refusal) — not a silent
skip; `124` reserved if a timeout wrapper is added. On a tree that has exercises or
solutions, verify-all exits `0` only when nothing failed and nothing was skipped
silently. An **empty** tree (no units yet, as in Phase 1) exits 0 and says so.
Pass `-RequireItems` to also require that at least one item was checked. CI turns
`-RequireItems` on when the first unit lands.

### 7.8 Unit composition and voice

Per unit, these are the rules. A05 and A17 have explicit exemptions below; that is the
rule for those units, not a loosening of this list.

- A unit may have **at most 5** exercises tagged `[WRITE]` or `[MODIFY]` — those two
  tags **share the cap**.
- at least 1 `[BUG]`;
- at least 1 `[PREDICT]` or `[WHATIF]`;
- at least 1 `[PORTAL]` or `[CLI]` where section 5 names a portal- or CLI-only skill for
  that unit; units with no such skill (A00, most of A06) are exempt;
- 2–3 drills, except A17 (0–1).

**A05 exemptions:** no required `[BUG]` or `[WHATIF]`. At least one `[PREDICT]` against
a CLI fixture is allowed and satisfies the predict slot. At least one `[PORTAL]` or
`[CLI]`. Drills are CLI-script drills (section 4.2). `[WRITE]` / `[MODIFY]` are not
required; include them only if a slice is genuinely Bicep-able (for example a role
assignment).

**A17 exemptions:** no required `[WRITE]`, `[MODIFY]`, `[BUG]`, or `[WHATIF]`. The unit
is `[PREDICT]`, `[EXPLAIN]`, `[PORTAL]` / `[CLI]` walkthroughs, and practice-assessment
work.

**Size.** Bicep-primary `[WRITE]` / `[MODIFY]` / `[BUG]` keep **S < 40**, **M 40–150**,
**L 150–300** lines of student Bicep (XS, if used, is < 15). For `[PORTAL]`, `[CLI]`,
`[EXPLAIN]`, `[PREDICT]`, `[WHATIF]`, and CLI drills, size is **time**: **S ≤ 25
minutes**, **M 25–60**, **L 60–120**. An exercise that mixes both uses the larger of
the two measures. Drill READMEs still use XS or S.

Voice: adult, specific, plain. Second person, present tense, active. No cheerleading, no
filler, no "simply," no "it is important to note." One term per concept, defined at first
use. Contrasts belong in tables with every cell filled. Anything load-bearing in a code
block is also said in prose.

### 7.9 Capstones and `lesson-demo/`

Capstones live at `capstones/cN-<name>/` with a unit-level `LESSON.md` or README plus
`eNN-<slug>/` exercise folders that use the same format as unit exercises (README,
`exercise.psd1`, starter, tests). Relative verify paths are in section 7.2.

`lesson-demo/` (under a unit, when present) is a **complete, already-passing** example
referenced from `LESSON.md`. Lint, `bicep build`, and PSRule must pass. There is no
starter/solution split, and it is not listed in verify-all's fail-until-worked table:
it must pass the way a solution does.

## 8. Harness design

Phase 1 infra implements this section. The behaviour below is the acceptance bar for
`scripts/verify-all.ps1`, `lint.ps1`, `selftest.ps1`, and `scripts/psrule.ps1`.

### 8.1 Commands

| Command | Does |
|---|---|
| `pwsh -File scripts/install-tools.ps1` | install or check pins from `scripts/toolchain.psd1` (`-CheckOnly`; CI uses `-Ci`) |
| `pwsh -File scripts/verify-all.ps1` | verify every starter and solution (offline layers only). An empty tree passes; add `-RequireItems` when units exist |
| `pwsh -File scripts/verify-all.ps1 -Only units/a06-storage-accounts` | prefix match; the mirrored solution comes along |
| `pwsh -File scripts/check.ps1` | student-facing: is *my* work in this folder (or `-Path`) done? Use this, not verify-all, while writing |
| `pwsh -File scripts/lint.ps1` | layout, manifests, `bicepconfig.json`, no `OUTPUT-PENDING`, no solutions links |
| `pwsh -File scripts/psrule.ps1` | PSRule (`Azure.Pillar.Security.L1`) over solutions and lesson-demos |
| `pwsh -File scripts/selftest.ps1` | throwaway fixtures that prove scaffold-fail, solution-pass, fidelity, and skip policy |
| `pwsh -File scripts/rep.ps1 <path>` | fresh copy into gitignored `reps/` |
| `pwsh -File scripts/lab/lab-up.ps1 -Path <exercise>` | checks `.lab-env.json` and the A02 budget gate (before `up.ps1`), then deploys if the exercise is a `[LAB]` |
| `pwsh -File scripts/lab/lab-down.ps1 -Path <exercise>` | deletes matching course-tagged lab groups; skips `lifecycle=persistent` unless `-IncludePersistent`; prints soft-delete warnings |
| `pwsh -File scripts/lab/lab-sweep.ps1` | *lists* leftover course-tagged groups and resources; persistent/expected groups do not count toward exit 1 |

CI runs lint, selftest, verify-all (without `-RequireItems` until the first unit lands),
`psrule.ps1`, and a dirty-tree check. It never runs the lab scripts.

### 8.2 Scaffold-OK rule (`WRITE`, `DRILL`, `MODIFY` starters)

1. No `#disable-next-line` used to hide a missing resource; no `#error`-style stop; no
   commented-out resource the tests would accept if uncommented.
2. For Bicep/ARM: `bicep build`, `bicep lint` (with the repo config), and PSRule succeed,
   or the ARM JSON parses and is lint- and PSRule-clean. For a CLI/PowerShell drill: the
   starter script parses.
3. `Invoke-Pester` on `main.tests.ps1` **fails**.
4. For `[WRITE]` (and Bicep drills) the failure is a failed structural assertion about
   `ExpectResources` / `ExpectOutputs`. For `[MODIFY]` it is a failed assertion about
   `ExpectProperties` — the resource type is already present; the starter is not
   required to omit it. For a CLI/PowerShell drill, the failure is that the script does
   not yet implement the required commands. The failure is not a compile or parse error,
   not an unexpected lint or PSRule error, and not a missing file.
5. The verdict line reads `scaffold OK: structural tests fail pending: …` and names the
   missing types, properties, or commands.

### 8.3 Solution pass rule

1. `bicep build`, `bicep lint`, and (when enabled) PSRule pass on the solution.
2. Pester structural tests pass and print `<id>: all checks passed`.
3. Every harness file of the starter exists in the solution and its harness part is
   byte-identical (section 7.5).
4. Every `capture*.txt` matches the current source hash of the files it claims to come
   from. A mismatch is `STALE`.
5. `[BUG]` solutions pass the lint, PSRule, or Pester check the starter failed (they are
   clean of every id in `ExpectDiagnostics`), and include `NOTES.md`.
6. If the exercise requires `ANSWER.md`, verify-all fails when the file is missing, is
   empty or whitespace-only, or is missing any heading listed in the exercise README
   and/or in `AnswerHeadings`. CI does not grade the quality of the prose. A shipped
   solution `ANSWER.md`, if any, is a model answer, not a hash the student must match.

### 8.4 Done means clean everywhere (student-facing)

An exercise is done when:

- its automated offline checks pass on the work the student wrote (or, for `[EXPLAIN]` /
  `[PREDICT]`, `ANSWER.md` has the required headings and is non-empty, and the shipped
  checks still pass);
- for `[BUG]`, `ANSWER.md` has the required headings, including the mechanism;
- for `[LAB]`, post-deploy assertions ran, **and** `lab-down` has been run, **and**
  `scripts/lab/lab-sweep.ps1` shows nothing unexpected for that prefix;
- no `out/` or compiled JSON has been left for commit.

### 8.5 Nothing is skipped silently

verify-all walks every entry under `units/`, `capstones/`, and `solutions/`. Anything that
is not an exercise, drill, lesson demo, `LESSON.md`, or `drills/README.md` is printed as a
`SKIP` row with its path and the reason, and counted. A clean tree for CI is **0 failed
and 0 skipped** (or a documented, explicit allow-list if a later pin requires one — the
default is zero). Missing solutions for `WRITE`, `DRILL`, `MODIFY`, and `BUG` are
failures, not skips. Orphan solutions are failures. A `lesson-demo/` is walked and
must pass like a solution; it is not a fail-until-worked starter.

`[LAB]` live steps are not "skipped" in verify-all: they are out of scope for the offline
run, and the offline artefacts for those exercises are still checked. A comment in the
verify row may say `offline only; live steps not run`. `[NO-LIVE]` is implicit except
on `[LAB]`; tests or scripts that would call `az`, `Connect-AzAccount`, or ARM without
a mock or fixture fail the exercise.

### 8.6 Self-tests

`selftest.ps1` builds a throwaway course tree and asserts: an untouched `[WRITE]` scaffold
is scaffold-OK; the same scaffold plus the missing resources passes; a dummy resource that
sneaks past a weak test is rejected by the sample tests authors are expected to copy; a
starter that fails to compile is reported as an exercise bug; harness edits in a solution
fail fidelity; stray directories are SKIP; orphan solutions fail; lint and PSRule are
invoked the same way CI will invoke them.

## 9. Toolchain pins and portability

- **Pin policy:** `scripts/toolchain.psd1` is the **single source** of toolchain pins.
  `docs/AUTHORING-INFRA.md` documents them; `lint.ps1` fails if the table, `ps-rule.yaml`,
  or the workflow drift from that file. `scripts/install-tools.ps1` installs or checks
  the pins. Phase 1 infra recorded the pins on `DESKTOP-AK42M6F` (21 November 2026)
  and on both CI images. Bumps are a deliberate PR, not "whatever the runner has today."
- **Pins recorded in Phase 1 (infra PR #3):** Bicep CLI `0.49.2` (standalone);
  Pester `5.9.1`; PSRule engine `2.9.0`; `PSRule.Rules.Azure` `1.47.0`; PSRule
  baseline `Azure.Pillar.Security.L1`; PowerShell 7.4.0 minimum; Azure CLI 2.76.0
  minimum (labs only). `bicep snapshot` exists in 0.49.2 and stays **optional** in
  verify-all (section 13.3). The `microsoft/ps-rule` action is **not** used.
- **Minimums already known (20 November 2026 research, still valid as floors):**
  Azure CLI 2.76.0+ for `--validation-level` (`Provider`, `ProviderNoRbac`,
  `Template`); Azure CLI 2.88.0+ only if a script uses `az bicep run --config`.
  Azure PowerShell 13.4.0+ has the equivalent ValidationLevel switch if a lab uses
  `Test-AzResourceGroupDeployment`. PSRule Bicep expansion is
  `AZURE_BICEP_FILE_EXPANSION: true`.
- **PSRule vs the Bicep linter:** language hygiene (unused parameters, secret outputs, and
  the old ARM-template style rules) is the Bicep linter's job. Several
  `Azure.Template.*` PSRule rules are deprecated from v1.36.0 and will be removed in
  PSRule v2 because the linter already covers them. PSRule is used for Azure resource and
  Well-Architected rules, not as a second Bicep parser.
- **arm-ttk:** optional, A01 ARM JSON only. Latest researched release was 0.27
  (2026-02-13). Not a default CI gate.
- **Portability:** every offline script runs under `pwsh` on Windows and on Ubuntu.
  Paths are joined with `Join-Path` / .NET APIs, not `C:\...` hardcoding, except documented
  examples in the student README. No bash-only verify path. Encoding is UTF-8.

## 10. Cost control and cleanup

A learner subscription can run a real bill. The course treats that as part of the
curriculum (A02) and as a rule for every author.

### 10.1 Where labs run

Labs run in the **personal MSA tenant and subscription** pinned in `.lab-env.json`
(section 3.2), using a dedicated course-tagged resource-group prefix (`lagb-`). That
subscription must not be a work or Deloitte subscription. Management-group exercises
need rights that many personal tenants do not have (section 13.3). A05 directory work
uses the disposable Entra test tenant and does not deploy billable Azure resources
into a work directory.

### 10.2 Naming and tags

Every lab resource (and every lab resource group) carries:

| Tag | Value |
|---|---|
| `course` | `LearnAzureByGrinding` |
| `unit` | `a12-virtual-machines` (folder name) |
| `exercise` | `a12-e01-create-vm` (full id) |
| `expires` | an ISO date the student or `lab-up` sets, shortly after the lab |
| `owner` | `n8` (or the signed-in user) |

Names use a short prefix (`lagb-` unless Phase 1 picks another) plus a unique suffix so
two exercises do not collide. `lab-down` and `lab-sweep.ps1` select by the `course` tag first,
then by unit or prefix. The A02 guardrails group uses the same tags minus `expires`,
plus `lifecycle=persistent` (section 10.3); it is not a same-day lab group.

### 10.3 Budget gate

A02-e01 is a `[LAB]` that ships an `up.ps1`. `lab-up` runs that script, and the script
runs `az deployment sub create`. The template deploys:

- A subscription-scope `Microsoft.Consumption/budgets@2024-08-01` named `.lab-env.json`
  `budget.name` (default `lagb-monthly`), monthly, `Cost`, amount in the **$10–$25**
  range (`budget.amount`, default `25`).
- Five notifications, the per-budget maximum Azure allows: **Actual** 50/80/100% and
  **Forecasted** 80/100%. There is no sixth slot for a Forecasted 50% alert. Each
  notification emails `budget.contactEmail` (the personal MSA address, not a work
  address) and an action group.
- The action group in a **persistent** resource group, `guardrails.resourceGroup`
  (default `lagb-guardrails`), tagged `course`, `unit=a02-cost-and-guardrails`,
  `exercise`, `lifecycle=persistent`, and `owner`, with **no** `expires` tag.

`lab-down` never deletes a group tagged `lifecycle=persistent` unless
`-IncludePersistent` is passed; it prints that it skipped the group and continues.
`lab-sweep` lists that group (and resources in it) as expected; they do not count
toward exit 1. Exit 1 is only for unexpected leftovers.

The budget gate runs in `lab-up` **before** the `up.ps1` branch, for every
resource-scope lab **outside A02** (A02 is exempt because it creates the budget;
A05 Entra-scope labs do not run the gate). It checks only that
`az consumption budget list` (subscription scope) returns a budget whose `name`
equals `budget.name` and whose `amount` is greater than 0. It does **not** check
notifications, thresholds, Forecasted alerts, the action group, or that the amount
matches `budget.amount`. A resource-group-scope budget is not seen. If the gate
fails, `lab-up` exits 3 and prints the fix (do the A02 budget lab, or
`-BudgetOverride`). `-BudgetOverride` deploys anyway and prints a loud warning
banner. `lab-up` still refuses if the active tenant does not match `.lab-env.json`
or looks corporate (section 3.2).

A02 also covers Advisor and, if authors put it here rather than A04, an Azure Policy that
restricts lab SKUs and regions (for example: one or two cheap regions, B-series or a short
allow-list, no Firewall/VPN SKUs). If the Policy lives in A04, `lab-up` still checks that
it is assigned before A06+ labs.

### 10.4 What costs money if left running

The lesson in A02, and every later `[LAB]` README that touches these, names them:

- Public IP addresses
- Azure Bastion
- Virtual machines without auto-shutdown (every lab VM **must** have auto-shutdown)
- App Service plans above Free/Basic, and empty plans left behind
- Load balancers with a public IP
- Recovery Services vaults (soft delete; slow to purge)
- Site Recovery, cross-region replication, zone-redundant SKUs used "because they sound
  safer"
- Azure Firewall, VPN Gateway, ExpressRoute — **out of scope** for this course's labs;
  do not author a `[LAB]` that creates them

Prefer: Standard_LRS, B-series or Policy-allowed small SKUs, no public IP when private
will do, Bastion only in a short guarded lab that is deleted the same day, Learn sandbox
or `[EXPLAIN]` for ASR failover.

### 10.5 Teardown and sweep

- `scripts/lab/lab-down.ps1` deletes the matching course-tagged resource group (or the
  resources for a path, unit, or tag set). It is the last step of every `[LAB]` README.
  A group tagged `lifecycle=persistent` (the A02 guardrails group) is skipped unless
  `-IncludePersistent` is passed.
- `scripts/lab/lab-sweep.ps1` *lists* every remaining course-tagged resource group and
  resource in the lab subscription, with name, type, region, and the `expires` tag.
  It is list-only. Persistent/expected groups are listed separately and do not count
  toward exit 1.
- Authors never commit a state file that contains a subscription ID or a secret. Parameter
  files in the repo use placeholders; students keep local `*.local.bicepparam` (gitignored)
  if needed.


### 10.6 CI

CI never logs in to Azure, never runs `lab-up`, and never holds Azure secrets in the
default workflow. See section 11 for the optional, opt-in live-smoke path.

### 10.7 Optional costly labs, Bicep up/down, and estimated costs

Nathan's decision (20 November 2026): every lab that can run up a meaningful bill is
**Optional**. The default path for that skill is a cheap or offline exercise (structural
Bicep, what-if, `[EXPLAIN]`, or a Microsoft Learn sandbox). The optional live path is a
same-day, guarded `[LAB]` with its own teardown.

**Bicep up/down design (implemented in Phase 1 infra, not in the spec-only drop):**

- Each optional costly lab ships an `up.bicep` (and a matching `.bicepparam` with
  placeholders) that deploys only that lab's resources into a **dedicated, course-tagged
  resource group** (tags in section 10.2, prefix `lagb-`).
- `scripts/lab/lab-up.ps1` checks `.lab-env.json` (section 3.2) and the A02 budget
  gate **before** `up.ps1` or `up.bicep`, for every resource lab outside A02. The gate
  checks only the budget's name and amount > 0 (section 10.3). For a typical costly
  lab it then creates or reuses that RG and deploys `up.bicep`. If the exercise ships
  `up.ps1` (A02-e01), that script runs instead and the script itself runs
  `az deployment sub create`. `lab-up` refuses to run on a tenant/subscription
  mismatch or a corporate-looking tenant.
- `scripts/lab/lab-down.ps1` deletes that RG (or the tagged resources) and **prints
  soft-delete / purge warnings** before it returns success: Recovery Services vaults,
  backup items, Key Vaults, and similar resources can linger in a soft-deleted state
  and block a clean delete. The script tells the student what to purge and how, and
  `scripts/lab/lab-sweep.ps1` still lists leftovers. The persistent A02 guardrails
  group is skipped unless `-IncludePersistent` is passed; lab-sweep lists it as
  expected, and it does not count toward exit 1.
- Leaving Bastion Basic/Standard, a public IP, an App Service plan, a Recovery Services
  vault with a protected instance, or Site Recovery replication running is how a "two
  hour" lab becomes a monthly bill. Tear down the same day.

#### Estimated Cost Table (East US, USD, 20 November 2026)

These are **estimates**, not quotes. They use Microsoft's public Retail Prices API
(<https://prices.azure.com/api/retail/prices>, `currencyCode=USD`) queried on
**20 November 2026**, for **East US** (`armRegionName eq 'eastus'`) except where a
meter is billed globally (Standard Load Balancer, Azure DNS). Official pricing pages
hide dollar amounts unless you are signed in; the API is the official numeric retail
source, and each row cites the matching pricing page. Actual bills vary by offer,
agreement, and currency. A 730-hour month is used only to show "left running" risk.
"1–2 hour lab run" assumes you deploy, finish the exercise, and delete the same day,
except where a fee is monthly (Backup, Site Recovery instance fees).

| Resource (optional lab) | SKU / meter | Rate | Fixed / minimum fees | Est. cost, 1–2 hour lab run | Official sources |
|---|---|---|---|---|---|
| Azure Bastion, Developer | Developer SKU | **Free** ($0/hour). No Developer meter in the Retail API. | None | **$0.00** | [Bastion pricing](https://azure.microsoft.com/en-us/pricing/details/azure-bastion/) |
| Azure Bastion, Basic | Basic Gateway + Standard static IPv4 | $0.19/hour + $0.005/hour PIP | Partial hours bill; PIP bills until deleted | **~$0.39–$0.40** for 2 hours. Left 730 hours: **~$142** | [Bastion](https://azure.microsoft.com/en-us/pricing/details/azure-bastion/), [IP addresses](https://azure.microsoft.com/en-us/pricing/details/ip-addresses/) |
| Azure Bastion, Standard | Standard Gateway (base includes two instances) + Standard static IPv4 | $0.29/hour + $0.005/hour PIP; extra instance $0.14/hour | Same | **~$0.59** for 2 hours. Left 730 hours: **~$215** | Same as Basic |
| Standard Public IPv4 (static) | Standard IPv4, static, East US | $0.005/hour (~$3.65 / 730 hours) | Bills until the IP resource is deleted, even if the VM is stopped | **~$0.005–$0.01** | [IP addresses](https://azure.microsoft.com/en-us/pricing/details/ip-addresses/) |
| Azure Disk Encryption lab | ADE feature is free. Representative lab: Linux `Standard_B1s` + 32 GB Standard HDD (S4) LRS + Key Vault Standard operations + Standard static PIP | VM $0.0104/hour; S4 disk $1.536/month (~$0.0021/hour); KV $0.03 / 10,000 operations; PIP $0.005/hour | Disk (and PIP, if you leave it) keep billing after the VM is deallocated | **~$0.04** for 2 hours if everything is deleted. Leftover disk ~$1.54/month; leftover PIP ~$3.65/month | [Linux VMs](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/), [Managed Disks](https://azure.microsoft.com/en-us/pricing/details/managed-disks/), [Key Vault](https://azure.microsoft.com/en-us/pricing/details/key-vault/), [IP addresses](https://azure.microsoft.com/en-us/pricing/details/ip-addresses/), [ADE FAQ](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-faq) |
| App Service plan, F1 Free | F1 (Windows or Linux) | $0/hour | Shared CPU; no SLA; **no custom domain TLS, no deployment slots** | **$0.00** (enough for a default `*.azurewebsites.net` app) | [App Service Windows](https://azure.microsoft.com/en-us/pricing/details/app-service/windows/), [App Service Linux](https://azure.microsoft.com/en-us/pricing/details/app-service/linux/) |
| App Service plan, B1 Basic | B1 | Linux $0.017/hour; Windows $0.075/hour | An empty plan still bills. Custom domain + App Service managed certificate (SNI) are available on Basic+ | **~$0.03–$0.15** for 2 hours (Linux vs Windows) | Same App Service pages |
| App Service plan, S1 Standard | S1 (needed for **deployment slots**) | Linux $0.095/hour; Windows $0.10/hour | Same empty-plan warning | **~$0.19–$0.20** for 2 hours | Same App Service pages |
| Azure Container Registry, Basic | Basic Registry Unit + storage | $0.1666/**day** (~$5/month); extra storage $0.10/GB-month (Basic includes 10 GB) | Daily meter: create-and-delete on the same calendar day is still about one day | **~$0.17** | [Container Registry](https://azure.microsoft.com/en-us/pricing/details/container-registry/) |
| Azure Container Instances | Standard Linux vCPU + memory, East US | $0.0405/vCPU-hour + $0.00445/GB-hour | Billed per second; no charge when the container group is gone | **~$0.09** for 2 hours at 1 vCPU + 1.5 GB | [Container Instances](https://azure.microsoft.com/en-us/pricing/details/container-instances/) |
| Azure Container Apps, Consumption | Standard (Consumption) vCPU, memory, requests | Active vCPU $0.000024/second (~$0.0864/hour); memory $0.000003/GiB-second (~$0.0108/GiB-hour); requests $0.40/million | Monthly free grant: 180,000 vCPU-seconds, 360,000 GiB-seconds, 2 million requests. Scale-to-zero is $0 | **Typically $0** for a short lab inside the monthly grant. Beyond the grant, ~$0.18 for 2 hours at 1 vCPU + 0.5 GiB active | [Container Apps](https://azure.microsoft.com/en-us/pricing/details/container-apps/) |
| Azure Load Balancer, Standard | First 5 rules + data processed + Standard PIP | Rules $0.025/hour (Global meter); additional rules $0.01/rule/hour; data $0.005/GB; inbound NAT rules free | **Partial hour bills as a full hour.** No hourly rule charge if no rules are configured | **~$0.06** for 2 hours with one rule set + a PIP; data usually pennies in a lab | [Load Balancer](https://azure.microsoft.com/en-us/pricing/details/load-balancer/), [IP addresses](https://azure.microsoft.com/en-us/pricing/details/ip-addresses/) |
| Azure DNS, public zone | First 25 public zones + queries | $0.50/zone/month (pro-rated daily); additional zones $0.10/zone/month; first 1 billion queries $0.40/million, then $0.20/million | Zone charge is daily-prorated. You do not need to delegate a registrar to create a zone | **~$0.02** (about one day of the $0.50 monthly zone fee) + ~$0 queries in a lab | [Azure DNS](https://azure.microsoft.com/en-us/pricing/details/dns/) |
| Recovery Services vault + Azure Backup (VM) | Azure VM protected instance + Standard LRS backup storage | Official page still has size tiers (≤50 GB, 50–500 GB, each additional 500 GB). Retail API East US on 2026-11-20 lists a single **Azure VM Protected Instance** meter at **$10.00/month**. LRS storage $0.0224/GB-month | **Instance fee is a monthly meter**, not hourly. A short lab that enables backup can still incur the month's instance charge. Soft-delete (default 14 days) blocks vault deletion until you undelete and purge; default 14-day soft-delete storage is not billed, but longer retention is | **Up to ~$10 in the month you protect a VM**, plus cents of LRS storage for a small disk — not "a few cents for two hours." Always run `lab-down` and follow the purge warning | [Backup pricing](https://azure.microsoft.com/en-us/pricing/details/backup/), [Soft delete](https://learn.microsoft.com/en-us/azure/backup/soft-delete-azure-backup-faq), [Delete a vault](https://learn.microsoft.com/en-us/azure/backup/backup-azure-delete-vault) |
| Azure Site Recovery (Azure-to-Azure) | Protected instance + replication storage + egress + failover VM | Instance **$25.00/month** after the **first 31 days free** per protected instance. Storage, transactions, data transfer, and failover/test-failover **compute still bill during those 31 days** | Leaving replication on past day 31 adds $25/month per VM. Failover creates a target VM you must delete | **First 31 days, short lab:** often **under ~$1–$2** if you replicate a small disk, do a brief B1s test failover, and tear down (storage/egress vary). **After day 31:** add **$25/month** if still protected | [Site Recovery](https://azure.microsoft.com/en-us/pricing/details/site-recovery/) |
| Azure Monitor / Log Analytics | Analytics Logs ingestion, East US | $2.30/GB ingestion; retention $0.10/GB-month after the included period (typically 31 days) | **First 5 GB/month Analytics Logs ingestion is free per billing account** | **$0** for a typical lab under the 5 GB grant | [Azure Monitor](https://azure.microsoft.com/en-us/pricing/details/monitor/) |

**Author rules that follow from this table:** prefer Bastion **Developer** when a live Bastion lab is offered; treat Basic/Standard as a "see the bill, then delete" optional extra. Prefer App Service **F1** or **Linux B1** unless the exercise needs slots (then a short **S1** lab). Prefer Container Apps Consumption inside the monthly free grant. Never leave Backup protection or Site Recovery replication enabled overnight. Azure Firewall, VPN Gateway, and ExpressRoute remain **out of scope**.

## 11. CI

`.github/workflows/ci.yml` runs on every pull request, on pushes to `main`, and on
`workflow_dispatch`. Two required legs, `fail-fast: false`:

| Leg | Runner | Notes |
|---|---|---|
| `windows-pwsh` | `windows-latest` | Student-shaped: `pwsh`, Azure CLI + pinned Bicep, Pester 5, PSRule |
| `ubuntu-pwsh` | `ubuntu-latest` | Same scripts under `pwsh` on Linux |

No macOS leg is required for v0.1 (section 13.3). Each required leg:

1. Print toolchain versions (`pwsh`, `az`, `bicep`, Pester, PSRule).
2. `pwsh -File scripts/lint.ps1`
3. `pwsh -File scripts/selftest.ps1`
4. `pwsh -File scripts/verify-all.ps1` (add `-RequireItems` once the first unit lands)
5. `pwsh -File scripts/psrule.ps1` (baseline `Azure.Pillar.Security.L1`). verify-all
   also runs PSRule per exercise with tag-aware expectations. The `microsoft/ps-rule`
   action is not used.
6. Fail if `git status --porcelain --ignored` is not empty.

A PR is mergeable only when both legs are green on its head commit. **Agents never merge a
PR, including their own; Nathan merges.**

Optional, **approved** (20 November 2026): a separate `workflow_dispatch` workflow
that runs a tiny live smoke (validate / what-if against an empty or throwaway
resource group) using **OIDC federated credentials**. It is not required for merge,
is off unless someone with repo access starts it by hand, and must not leave
billable resources behind. Phase 1 infra may add the workflow file; this spec-only
drop does not.

**What federated credentials (OIDC) are, in plain language.** The Entra identity is
the app registration (or user-assigned managed identity) in the personal tenant that
GitHub Actions presents itself as. GitHub Actions can prove "this job is a run of this
workflow, in this repository, in this GitHub Environment" without storing a password.
At the start of the job, GitHub issues a **short-lived signed JWT** (an OpenID Connect
token). Microsoft Entra ID has a **federated credential** on that identity that trusts
GitHub's token issuer (`https://token.actions.githubusercontent.com`) only when the
token's subject matches the configured repo and Environment. The federated subject is
**pinned to a GitHub Environment with a required reviewer**, not to a wildcard branch.
Entra then issues a short-lived Azure access token for that identity. Official docs:
<https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect>
and
<https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation>.

**Why there are no stored secrets.** There is no client secret or certificate in
GitHub Secrets to leak, expire, or rotate. The workflow may still hold the
*identifiers* (tenant id, subscription id, client id), which are not credentials.
The trust is scoped: a workflow in another repository, or a job that is not a run
of the named Environment, cannot exchange a token for that Azure identity. The
required reviewer on the Environment is what makes a `workflow_dispatch` live-smoke
a deliberate act, not an accidental push to a matching branch. The default CI legs
still do not log in to Azure at all.

## 12. Authoring split and phases

Lesson learned in `a-simple-method` and written into the data-structures SPEC: two authors
must not share a writable path. **Every path has exactly one owner.** Nobody edits a path
they do not own; they ask its owner, who makes the change.

### 12.1 Phases

- **Phase 1 — spec and infra (Bruce).** This file and the student README are the start.
  Then: `bicepconfig.json`, `ps-rule.yaml`, `lib/`, the scripts in section 6, `.gitignore`,
  CI, `docs/AUTHORING.md`, `docs/AUTHORING-INFRA.md`, and `scripts/selftest.ps1` proving
  the scaffold-fail / solution-pass / fidelity rules. No student unit is authored until
  the harness exists. A sample unit (or a fixture unit under `scripts/selftest` only) may
  be used to prove the harness (chosen in Phase 1 infra, section 13.3).
- **Phase 2 — units, with disjoint ownership.** **Phase 2 starts after Nathan merges
  the spec PR** (PR #1). Monk and Jack Gable will be looped in to review that PR once
  it is open. After the merge, lessons and scaffolds can proceed in parallel against
  the names in section 5. Solutions follow scaffolds. Open a PR per agreed slice;
  keep it green; do not merge.
- **Phase 3 — technical review and green CI.** Bruce reviews; all CI legs green;
  `OUTPUT-PENDING` empty; coverage matrix still complete against a fresh fetch of the
  official study guide. Nathan merges.

### 12.2 Ownership (Phase 2) — approved 20 November 2026

Monk writes `LESSON.md` and the other named student prose. Jack Gable owns exercises
and drills under `units/` and `capstones/`. Bruce owns `solutions/`, infra
(`scripts/`, `lib/`, CI), `docs/SPEC.md`, and technical review.


| Owner | Paths |
|---|---|
| Monk | `units/*/LESSON.md`, `units/*/drills/README.md`, `README.md`, `PROGRESS.md`, `docs/ROADMAP.md`, student-facing prose in those files |
| Jack Gable | everything under `units/` and `capstones/` **except** `LESSON.md` and `drills/README.md` (exercise and drill starters, READMEs, tests, manifests, lesson-demo sources) |
| Bruce | `docs/SPEC.md`, `docs/AUTHORING.md`, `docs/AUTHORING-INFRA.md`, `scripts/`, `lib/`, `bicepconfig.json`, `ps-rule.yaml`, `.github/`, `.gitignore`, everything under `solutions/`, technical review |

Jack's scaffold PR cannot go green alone if CI requires a solution for each test-fail
starter. The same pairing rule as the data-structures course applies: Jack finishes
scaffolds and says so; Bruce pushes only `solutions/<those units>/**` to the same branch;
Jack does not push again unless Bruce asks. Nobody pushes to a branch while its owner is
working on it. A PR touches only paths its author owns.

**Slug and title handshake.** When a unit is assigned, Jack proposes a list of
`eNN-<slug>` + title + tag (and drill slugs). Monk writes the `LESSON.md` exercise
table (and the unit-level `drills/README.md` list) from that exact list. Neither
changes a slug or a title without the other. The same rule will be repeated in
`docs/AUTHORING.md` when Phase 1 writes that file.

Technical doubts go in the author's own `docs/review/<name>.md`, with unit, file, quoted
text, and the doubt. Bruce resolves them in review.

### 12.3 Rules every author follows

- Every `[WRITE]`, `[DRILL]`, and `[MODIFY]` starter fails its structural or script test
  until the student does the real work, and compiles or parses cleanly before that (and,
  for Bicep, is lint- and PSRule-clean). No stubs, no stop lines. `[BUG]` starters
  build, and may fail only the diagnostics named in `ExpectDiagnostics`.
- Solutions live only in `solutions/`, pass verify-all on both CI legs, and keep the
  shipped harness byte-identical outside the `StudentRegion`.
- No README links to solutions.
- No build artefacts in a commit or left in the tree.
- `[LAB]` exercises obey section 10. Authors must not add a lab that creates Firewall,
  VPN Gateway, or other out-of-scope billable resources. There is no `[LAB]` in A01.
- Never invent tool or portal output. A what-if or other capture is real command output,
  or the file contains `OUTPUT-PENDING` (which fails verify-all and blocks merge).
- Agents never merge; Nathan merges.

## 13. Decisions

### 13.1 Resolved decisions (20 November 2026)

Nathan answered the open questions from spec v0.1. The following are now the plan of
record (and are written into the sections they affect):

1. **Public repository and PR.** The course lives in the public GitHub repository
   `MayTheSForceBeWithYou/LearnAzureByGrinding`
   (<https://github.com/MayTheSForceBeWithYou/LearnAzureByGrinding>). Default branch
   is `main`. The first commit on `main` is a minimal tree (`.gitignore` and a short
   README). This SPEC and the student README land on branch `docs/spec` as PR #1
   targeting `main`. **Agents never merge; Nathan merges.** Phase 2 (units and
   exercises) starts only after that merge. Monk and Jack Gable will be asked to
   review PR #1 once it is open. PR #1 was merged to `main` on 21 November 2026.
   This drop does not author Phase 1 scripts, CI workflows, units, exercises, or
   solutions.
2. **Tenant and subscription.** Use the personal MSA
   `MayTheSForceBeWithYou@gmail.com`: its Default Directory Entra tenant and its
   Azure subscription (Free Account if still eligible, otherwise PAYG) for resource
   labs A00–A04 and A06–A17. Create a dedicated disposable Entra ID Workforce test
   tenant, in the same portal, for A05 only. A02 deploys a $10–$25/month budget with
   five notifications: Actual 50/80/100% and Forecasted 80/100% (the per-budget
   maximum). Isolation guardrails (separate
   browser profile, `az account` checks, `az login --tenant`, gitignored
   `.lab-env.json`, hard refuse in `lab-up` / `lab-down`) are required. Details
   are in section 3.2.
3. **Costly labs are Optional.** Bastion, Standard public IPs, ADE (Key Vault + VM
   + disk), App Service B1/S1 (custom domain, managed TLS, slots), ACR, ACI,
   Container Apps, Standard Load Balancer, Azure DNS, Recovery Services / Backup,
   Site Recovery, and Log Analytics beyond the free grant are optional live labs.
   Each has its own `up.bicep` plus `lab-up.ps1` / `lab-down.ps1` (tagged RG,
   teardown, soft-delete purge warnings). The estimated cost table is section 10.7
   (East US, 20 November 2026, official pages + Retail Prices API).
4. **Custom domain.** A14 uses a **subdomain** of Nathan's domain `skopekreep.com`
   (for example `az104-lab.skopekreep.com`) so root-domain records are not
   disrupted. Learners with no domain use the alternative path in A14
   (`*.azurewebsites.net`, an Azure DNS zone walkthrough without registrar
   delegation, or an optional cheap domain purchase).
5. **OIDC live-smoke.** The optional `workflow_dispatch` OIDC live-smoke workflow
   is approved. Section 11 explains federated credentials and why no client secret
   is stored. Default CI still never logs in to Azure. The workflow is not a merge
   requirement.
6. **`[WRITE]` rule.** Section 4.4 is approved: starters compile with `bicep build`
   and fail a Pester structural test over the compiled JSON until the student writes
   the real resources. No stub stop lines. The beginner explanation in 4.4 maps this
   to the C courses' compile-OK / link-fail discipline and to what `verify` feels
   like.
7. **Ownership (approved).** Monk owns `LESSON.md` and the student-facing prose
   named in section 12.2. Jack Gable owns exercises and drills under `units/` and
   `capstones/`. Bruce owns `solutions/`, infra (`scripts/`, `lib/`, CI),
   `docs/SPEC.md`, and technical review. Phase 2 starts after Nathan merges the
   spec PR.

Related v0.1 items that those answers also close: the first budget lab stays in
**A02** (not A01); labs use the personal subscription with a dedicated tagged
resource-group prefix and the `.lab-env.json` pin, not a work tenant.

### 13.2 Phase 1 local-pinning items (exact versions on `DESKTOP-AK42M6F`)

Recorded in Phase 1 infra (PR #3) in `scripts/toolchain.psd1` and documented in
`docs/AUTHORING-INFRA.md`: Bicep CLI 0.49.2, Pester 5.9.1, PSRule 2.9.0,
PSRule.Rules.Azure 1.47.0, baseline `Azure.Pillar.Security.L1`, PowerShell 7.4.0
minimum, Azure CLI 2.76.0 minimum. The `microsoft/ps-rule` action is not used.
`bicep snapshot` exists in 0.49.2 and stays optional in verify-all (section 13.3).

### 13.3 Defaults retained unless Phase 1 infra has a reason to revisit

- `bicep snapshot` stays **optional** in verify-all until the pin in 13.2 says
  otherwise.
- CI for v0.1 is `windows-latest` + `ubuntu-latest` only (no macOS `pwsh` leg).
- `arm-ttk` stays an **optional** extra on A01 raw ARM JSON exercises only.
- Management-group *creation* may be blocked on a personal tenant; A03 covers
  management groups as `[EXPLAIN]` plus read-only `[CLI]` when create/assign is
  not available, and as a Bicep `[LAB]` only when the personal tenant actually
  allows it.
- Whether Phase 1 infra proves the harness with a public sample unit under
  `units/` (as D01 did in the data-structures course) or only with throwaway
  fixtures under `scripts/selftest.ps1` is chosen when the harness is written.

### 13.4 Resolved decisions (21 November 2026)

Resolutions of the exercise/drill review (Jack Gable) and the pedagogy review
(Monk), decided by Bruce as SPEC owner, and written into the sections they affect.
The short list is in the 0.3 changelog.

## 14. Changelog

- 0.3 (21 November 2026): resolutions of the exercise/drill review (Jack Gable) and
  the pedagogy review (Monk), decided by Bruce as SPEC owner.

  Jack Gable (exercise and drill format): CLI/PowerShell drills parse and fail a
  Pester test against a fixture or `az` / `Get-Az*` mock, with a test hook so
  verify-all never logs in; `[MODIFY]` uses `ExpectProperties` while `[WRITE]` keeps
  `ExpectResources`; `Tags` is a string array and `StudentRegion` is
  `below-marker` / `above-marker` / `whole-file`; exercise verify paths use
  `../../../scripts` (the drill-depth typo is fixed) and capstones use `eNN` folders;
  `[WRITE]` / `[MODIFY]` starters are lint- and PSRule-clean; `[BUG]` starters build
  and may fail only `ExpectDiagnostics`; A01 is offline only and the first live
  deploy (with a live export) is in A02; `ANSWER.md` is checked for presence and
  required headings, not prose quality; A05 and A17 composition exemptions are
  stated as rules, not a loosening; what-if captures are real or `OUTPUT-PENDING`;
  `[NO-LIVE]` is implicit except on `[LAB]`; `[PORTAL]` / `[CLI]` default to an
  offline fixture; size is lines for Bicep-primary work and time for portal/CLI/
  explain/predict/what-if and CLI drills; `[WRITE]` and `[MODIFY]` share a cap of 5
  per unit; A12 and A14 may combine bullets without raising targets; `lesson-demo/`
  is an already-passing example.

  Monk (pedagogy and sequencing): A07 no longer depends on VNets or Azure Files
  (storage VNet/service-endpoint firewalls move to A10; identity-based Azure Files
  access moves to A08); A01 offline export/decompile plus A02 live export; A05 hard
  tenant refusal via `expectedEntraTenantId`; `## Advance organizer`; official docs
  are reference, not the reading; LESSON.md default cap 300, with a documented 450
  exception for A01, A05, A12, A14, and A16; slug/title handshake between Jack and
  Monk; unit-level `drills/README.md` format; capstones after A04 / A11 / A16; OIDC
  identity defined and federated subject pinned to a GitHub Environment with a
  required reviewer; MSA wording no longer implies Microsoft created the Gmail
  address; "simply expire" removed; break-glass sentence split; Microsoft 365
  Developer Program fallback notes expiry; A17 Entra review uses the A05 test
  tenant or a Learn sandbox; public README no longer carries Nathan's Windows path,
  Gmail address, or Deloitte.

  Aligned with infra PR #3 (`infra/phase1`, head `d98d5a8`): Bicep linter rules stay
  at `warning` and the harness fails on warnings, so `[BUG]` starters still compile
  under Bicep 0.49.2; verify-all passes on an empty tree and `-RequireItems` waits
  for the first unit; PSRule baseline is `Azure.Pillar.Security.L1`, run through
  `scripts/psrule.ps1` and verify-all (pending `Azure.Storage.LocalAuth` question for
  A07); lab scripts live in `scripts/lab/` (`lab-sweep.ps1`); corporate-tenant
  refusal also covers non-allowlisted custom domains and the signed-in user name;
  the course root is `lib/AzGrinding.psd1`; students use `scripts/check.ps1`, and
  pins live in `scripts/toolchain.psd1` (`scripts/install-tools.ps1`, `lib/templates/`).

  A02 guardrails and budget notifications, aligned with infra PR #3 (`7b57240`):
  an Azure budget allows at most five notifications, so alerts are Actual 50/80/100%
  plus Forecasted 80/100%; A02-e01 ships `up.ps1` (`az deployment sub create`) for a
  subscription-scope `Microsoft.Consumption/budgets@2024-08-01` named `budget.name`
  (default `lagb-monthly`); the action group lives in the persistent
  `guardrails.resourceGroup` (default `lagb-guardrails`); lab-down skips that group
  unless `-IncludePersistent`; lab-sweep lists it as expected (not exit 1); the
  budget gate runs before `up.ps1` on every resource lab outside A02 and checks only
  the budget's name and amount > 0; live export uses `az deployment sub export`.

  Lesson vs fixture capture gate (22 November 2026): a lesson defers a missing
  capture in prose and must not use the `OUTPUT-PENDING` token; the token belongs
  in the exercise or drill fixture / capture file, where lint and verify-all fail
  until real output replaces it. Never invent tool or portal output.

- 0.2 (20 November 2026): Nathan's decisions applied. Beginner tenant and subscription
  setup (personal MSA Default Directory, disposable A05 Entra test tenant, Free vs
  P1/P2 trial warning, Free Account vs PAYG, A02 $10–$25 budget alerts, Deloitte
  isolation and `.lab-env.json`). All costly labs marked Optional, with `up.bicep` /
  `lab-up` / `lab-down` design and an East US estimated cost table (Retail Prices API
  + official pricing pages, 20 November 2026). A14 uses `az104-lab.skopekreep.com` plus
  a no-domain alternative. Optional OIDC `workflow_dispatch` live-smoke approved, with
  a beginner explanation of federated credentials. `[WRITE]` rule approved, with a
  beginner explanation mapping to the C courses' compile-OK / link-fail discipline.
  Phase 2 ownership approved; Phase 2 starts after Nathan merges the spec PR. Section
  13 now separates resolved decisions from Phase 1 local-pinning items. Still no units,
  exercises, solutions, or Phase 1 scripts in this drop.
- 0.1 (Phase 1): first version. Purpose, environment (Windows-first), tags and the
  compile-OK / test-fail starter rule, verification layers, curriculum A00–A17 and three
  capstones, full AZ-104 coverage matrix against the 20 November 2026 study-guide fetch,
  cost control, CI shape, authoring split, and open decisions. No units, exercises, or
  solutions authored in this drop.
