# Learn Azure by Grinding

An IaC-first, grind-style course toward a confident pass of Exam AZ-104: Microsoft Azure
Administrator. Bicep is the primary language. ARM JSON is something you read, modify,
export, and decompile. Skills the exam measures in the portal or the CLI are taught that
way, not faked as templates.

The plan of record is [`docs/SPEC.md`](docs/SPEC.md). Authors follow the authoring docs
named there once Phase 1 infra lands. Your ledger will be `PROGRESS.md`.

> **Status:** the plan of record is [`docs/SPEC.md`](docs/SPEC.md). No units, exercises,
> drills, capstones, or solutions have been authored yet, and the harness (`scripts/`,
> `lib/`, `bicepconfig.json`, CI) is still to come. Do not expect `verify-all.ps1` or a
> course map of finished folders in this tree today. Phase 2 starts after the remaining
> specification review is merged.

## What this will be

A sibling of `LearnCMemoryByGrinding` and `LearnCDataStructuresByGrinding`: a lesson, then
exercises that fail their tests until you do the real work, drills you repeat from a fresh
copy, and a separate `solutions/` tree that no README links to. `[WRITE]` starters are
legal Bicep (`bicep build` succeeds) and fail a Pester structural test over the compiled
JSON until you write the real resources — the same "compiles but will not link" discipline
as the C courses. The official AZ-104 skills outline is mapped, bullet by bullet, in the
spec.

This course is **Windows-first** (PowerShell 7, Azure CLI, Bicep). That is a deliberate
departure from the Arch-Linux-on-WSL rule of the C courses. CI will also prove the
offline path on Ubuntu.

## Official exam pages

Re-check these when you start a unit, and again before you sit the exam:

- Study guide: <https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104>
- Certification: <https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/>

## Environment (when the harness exists)

You will need PowerShell 7.4+, Azure CLI 2.76 or later, a pinned Bicep CLI, Pester 5, and
PSRule for Azure. Exact pins will live in `docs/AUTHORING-INFRA.md`.

Live labs use a **personal** Microsoft account and its Azure subscription, never a work
tenant. Keep resource labs in that personal tenant and subscription. Use a separate,
disposable Entra ID test tenant for directory work (users, groups, SSPR, and similar).
Pin the expected tenant and subscription in a local, gitignored lab-env file so scripts
can refuse to run against the wrong directory. Details and a worked example are in the
spec, section 3.2. Costly labs (Bastion Basic/Standard, public IPs, paid App Service
plans, Backup, Site Recovery, and similar) are **optional**, each with a same-day
teardown path. Default CI never deploys to Azure.

## Course map

The unit list, capstones, and coverage matrix are in [`docs/SPEC.md`](docs/SPEC.md)
section 5. They are the plan, not a claim that the folders already exist. When the
units exist, attempt capstone C1 after A04, C2 after A11, and C3 after A16.
