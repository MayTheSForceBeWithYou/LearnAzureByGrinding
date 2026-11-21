# Authoring infrastructure: harness, pins, and scripts

This is the mechanics companion to `docs/SPEC.md` (sections 3, 4.3–4.5, 6–11). It describes what
Phase 1 infra ships, the exercise format it enforces (spec v0.3 fields), and how an author runs
every check locally on Windows. Everything here is **offline**: no script except the three lab
scripts ever calls Azure, and those three are never run by CI.

## 1. What is in the repo

| Path | What it is |
|---|---|
| `bicepconfig.json` | Bicep linter settings for the whole repo (section 4) |
| `ps-rule.yaml` | PSRule for Azure settings: Bicep expansion, pinned module, `@course` baseline group (section 5) |
| `.lab-env.example.json` | Template for your local, gitignored `.lab-env.json` (section 10) |
| `scripts/toolchain.psd1` | The single source of truth for toolchain pins (section 2) |
| `scripts/install-tools.ps1` | Installs or checks the pins (`-CheckOnly`); CI uses `-Ci` |
| `scripts/verify-all.ps1` | Every starter, solution, and lesson demo, by tag (section 7) |
| `scripts/check.ps1` | Student-facing: is *my* work in this folder done? |
| `scripts/lint.ps1` | Layout, pins, configs, manifests, portability, `OUTPUT-PENDING`, solution links |
| `scripts/psrule.ps1` | PSRule over `solutions/**` and `units/*/lesson-demo/**` (must be clean) |
| `scripts/selftest.ps1` | Tests of the harness itself (section 9) |
| `scripts/rep.ps1` | Fresh copy of a drill or exercise into gitignored `reps/` |
| `scripts/internal/` | Verify engine (`Verify.psm1`) and the isolated Pester runner |
| `scripts/selftest/` | Lib unit tests and the throwaway fixtures selftest composes into temp trees |
| `scripts/lab/` | `lab-up.ps1`, `lab-down.ps1`, `lab-sweep.ps1`, `LabGuard.psm1`, and their offline tests |
| `lib/AzGrinding.psd1/.psm1` | Shared helpers for exercise Pester harnesses and the scripts (section 6) |
| `lib/templates/` | Author-only skeletons: `exercise.psd1`, `write.tests.ps1`, `modify.tests.ps1`, `cli-drill.tests.ps1` |
| `.github/workflows/ci.yml` | Two legs, `windows-pwsh` and `ubuntu-pwsh` (section 11) |

## 2. Toolchain pins

Verified on `DESKTOP-AK42M6F` on 21 November 2026 (PowerShell 7.6, Azure CLI 2.91.0) and on
both CI images. Pins live in `scripts/toolchain.psd1`; `lint.ps1` fails if this table, `ps-rule.yaml`,
or the workflow drift from it. A bump is a deliberate PR.

| Tool | Pin | Notes |
|---|---|---|
| Bicep CLI | `0.49.2` | Standalone release binary; `az bicep install` on the author machine also installed 0.49.2 |
| Pester | `5.9.1` | Not the in-box Windows PowerShell 3.4.0; 6.x is out and deliberately not used (SPEC says 5.x) |
| PSRule | `2.9.0` | Engine required by PSRule.Rules.Azure |
| PSRule.Rules.Azure | `1.47.0` | Bicep expansion via `AZURE_BICEP_FILE_EXPANSION: true` |
| PSRule baseline | `Azure.Pillar.Security.L1` | Shipped inside the pinned module, mapped to the `@course` group in `ps-rule.yaml` |
| PowerShell | `7.4.0` minimum | All scripts are `pwsh`; Windows PowerShell 5.1 is not supported |
| Azure CLI | `2.76.0` minimum | Only `[LAB]` work needs it. CI never signs in |
| `actions/checkout` | `v7.0.1` (pinned by SHA) | |

`bicep snapshot` exists in 0.49.2 (`bicep --help` lists it) but stays **optional**: verify-all does
not require snapshots (SPEC 13.3). The `microsoft/ps-rule` action is not used; CI runs the same
pinned module through `scripts/psrule.ps1` and verify-all, which the spec allows (section 11, step 5).

### Install on Windows (once)

```powershell
cd C:\Users\n8ppr\dev\Azure\LearnAzureByGrinding
pwsh -File scripts/install-tools.ps1          # modules at the pins (CurrentUser) + Bicep 0.49.2 in ~/.lagb
$env:LAGB_BICEP = "$HOME\.lagb\bicep-0.49.2\bicep.exe"   # add to $PROFILE
pwsh -File scripts/install-tools.ps1 -CheckOnly
```

The harness finds Bicep in this order: `$env:LAGB_BICEP`, `bicep` on `PATH`, then
`~/.azure/bin/bicep(.exe)` (where `az bicep install` puts it). Course scripts always call the Bicep
CLI directly, never `az bicep build`, so the repo `bicepconfig.json` is the one used (SPEC 4.5).

## 3. Commands authors run

```powershell
pwsh -File scripts/lint.ps1
pwsh -File scripts/selftest.ps1                       # ~3 min; -Case 'bug-*' for one group
pwsh -File scripts/verify-all.ps1                     # everything
pwsh -File scripts/verify-all.ps1 -Only units/a06-storage-accounts   # prefix; mirrored solutions come along
pwsh -File scripts/verify-all.ps1 -Only units/a06-storage-accounts -NoPSRule   # faster local loop; CI never skips PSRule
pwsh -File scripts/psrule.ps1
Invoke-Pester scripts/lab/tests                       # lab guard tests (az mocked)
```

Students run `pwsh -File ../../../scripts/check.ps1` from an exercise folder
(`../../../../scripts/check.ps1` from a drill), or `scripts/rep.ps1 <drill>` and then
`scripts/check.ps1 -Path reps/<id>/<stamp>`.

Exit codes follow SPEC 7.7: `0` pass, `1` a check failed (or verify-all printed a SKIP), `2` usage or
missing toolchain, `3` a lab refused by the guard.

## 4. Linter levels: warnings, enforced like `-Werror`

Every enabled rule in `bicepconfig.json` is `warning`, and `use-recent-api-versions` (results change
with the calendar) and `use-user-defined-types` are `off`. The harness treats **every warning and
error as a finding** (`Get-LintFindings`), so a starter or solution with a warning fails, exactly as
the C courses compile with `-Werror`.

Why not `error` in the config: Bicep 0.49.2 makes `bicep build` **fail** on an error-level linter
diagnostic. A `[BUG]` starter whose defect is a linter rule (a secret in an output, say) must still
compile so its Pester harness can run (SPEC 4.3). Keeping the config at `warning` and failing in the
harness gives both. `lint.ps1` rejects any rule set to `error`.

Consequence for authors: a harness section above the marker must not declare a parameter only the
student's code uses (`no-unused-params` would fire on the untouched starter). Put such parameters
below the marker in the solution, or use them in the shipped part.

## 5. PSRule for Azure

`ps-rule.yaml` pins `PSRule.Rules.Azure` `1.47.0`, turns on `AZURE_BICEP_FILE_EXPANSION` (with a 60 s
timeout for CI cold starts), and maps the `@course` baseline group to `Azure.Pillar.Security.L1`.
Every course call uses `-Baseline '@course'`, so the rule set only changes with the module pin.

`Azure.Pillar.Security.L1` was chosen over a full `Azure.GA_*` baseline on purpose. The GA baselines
fail `Azure.Storage.UseReplication` on `Standard_LRS`, `Azure.Resource.UseTags` on every untagged
resource, and so on, which contradicts SPEC 10.4 ("prefer Standard_LRS") and would bury beginners.
Security L1 is the short list of security defaults (`Azure.Storage.SecureTransfer`,
`Azure.Storage.MinTLS`, `Azure.Storage.LocalAuth`, …) that also make good `[BUG]` defects.

Which files: `scripts/psrule.ps1` passes explicit paths (all `.bicep` under `solutions/` and
`units/*/lesson-demo/`). verify-all runs PSRule per exercise with tag-aware expectations. A bare
`Invoke-PSRule -InputPath .` uses `input.pathIgnore`, which limits discovery to course Bicep and
excludes `scripts/**` (selftest fixtures fail on purpose); it will report `[BUG]` starters.

## 6. Exercise format (spec v0.3)

### `exercise.psd1`

Starter, solution, drill, and lesson-demo manifests share these keys (template:
`lib/templates/exercise.psd1`). Unknown keys fail.

| Key | Type | Meaning |
|---|---|---|
| `Tags` | string[] | First tag is **primary** and picks the rule below. Words: `WRITE MODIFY DRILL BUG PREDICT WHATIF EXPLAIN LAB PORTAL CLI NO-LIVE`. `LAB`/`NO-LIVE` cannot be primary; drills are primary `DRILL` and never `LAB` |
| `Entry` | string | Student-facing file: `.bicep`, ARM `.json`, or `.ps1` (CLI). Default `main.bicep` |
| `Test` | string | Pester 5 harness. Default `main.tests.ps1`. Required for WRITE/MODIFY/DRILL, and BUG without `ExpectDiagnostics` |
| `StudentRegion` | string | `below-marker` (default) / `above-marker` / `whole-file`: the part of `Entry` the student may edit |
| `ExpectResources` | string[] | Resource types the compiled template must contain (the "symbol list"). Nested child resources and module deployments are flattened |
| `ExpectOutputs` | string[] | Output names the template must declare |
| `ExpectProperties` | hashtable[] | `@{ ResourceType; Path; Value }` or `Match` (regex) in place of `Value`. `Path` is dotted with `[n]` indexes (`properties.securityRules[0].properties.access`). Satisfied when any resource of that type matches. Values compare against compiled JSON, so a Bicep expression compiles to an ARM expression string. Strings compare case-insensitively; `$true` does not match `'true'` |
| `ExpectDiagnostics` | string[] | BUG only: the exact set of lint rule ids and PSRule rule names the starter fails |
| `AnswerHeadings` | string[] | Exact heading lines `ANSWER.md` must contain, each with text under it |

Validation also requires: WRITE/DRILL template entries declare `ExpectResources` or
`ExpectOutputs`; MODIFY template entries declare `ExpectProperties` (or resources/outputs); a WHATIF
folder has a `capture*.txt` or `whatif*.txt`; a marker region has the marker line.

### The marker line

`---- Your resources go below this line. ----` (any `---- Your … go(es) below this line. ----`
wording) in the comment style of the entry: `//` in Bicep, `#` in PowerShell, and `//` **inside the
`resources` array** for ARM JSON (`ConvertFrom-Json` and ARM both accept `//` comments). For ARM
JSON `[MODIFY]` work prefer `StudentRegion = 'whole-file'` and grade the edit with `ExpectProperties`.

### Harness tests

Copy a template from `lib/templates/`. The first lines find the course root by walking up to
`lib/AzGrinding.psd1`, so the identical file works in `units/`, `solutions/`, `solutions/capstones/`,
and `reps/`:

```powershell
BeforeAll {
    $root = $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'lib/AzGrinding.psd1'))) { $root = Split-Path $root -Parent }
    Import-Module (Join-Path $root 'lib/AzGrinding.psd1') -Force
    $manifest = Get-ExerciseManifest -Path $PSScriptRoot
    $template = Get-CompiledTemplate -Directory $PSScriptRoot -Entry $manifest.Entry
}
```

Assert in `It` blocks, never in `BeforeAll` (a failing `BeforeAll` is reported as a harness crash, not
a structural failure). Always assert at least one property of each required resource, so a dummy
resource does not pass (selftest case `dummy-resource-fails-the-sample-test`).

Helpers (`lib/AzGrinding`): `Get-CompiledTemplate`, `Invoke-BicepBuild` (in memory, `bicep build
--stdout`), `Get-TemplateResources -Type`, `Get-PropertyValue`, `Test-/Assert-ExpectResources`,
`Test-/Assert-ExpectOutputs`, `Test-/Assert-ExpectProperties`, `Get-LintFindings`,
`Invoke-CoursePSRule`, `Get-ExerciseManifest`, `Test-AnswerFile`, `Enable-AzMock` /
`Disable-AzMock` / `Get-AzMockCalls`, `Write-ChecksPassed`.

### CLI drills and `[CLI]` work: the az mock

The student writes PowerShell below the marker in `main.ps1`; it must parse; the Pester harness
fails until the work exists and is graded against fixtures:

```powershell
Enable-AzMock -Fixtures @{ 'group list' = (Get-Content -Raw (Join-Path $PSScriptRoot 'fixtures/group-list.json')) }
. (Join-Path $PSScriptRoot 'main.ps1')
# ... It: Get-CourseGroupNames | Should -Be @(...); (Get-AzMockCalls)[-1] | Should -Match '--tag course='
AfterAll { Disable-AzMock }
```

Fixture keys are argument prefixes; the longest match wins; a reply is a string (usually checked-in
JSON), a scriptblock, or an object (serialised). An unmatched call throws. Pester `Mock az` also works.

### NO-LIVE

Everything except `[LAB]` is NO-LIVE. verify-all enforces it twice:

1. **Static scan.** Any `.ps1`/`.psm1` in the item that calls `az …`, `Connect-AzAccount`,
   `Invoke-AzRestMethod`, `Get-AzAccessToken`, `New-Az*Deployment`, `Test-Az*Deployment`, or
   `management.azure.com` fails unless the test file uses `Enable-AzMock` or a Pester `Mock` of it.
2. **Runtime trap.** Pester runs in a child `pwsh` where `az` and those cmdlets are functions that
   throw `NO-LIVE`. An unmocked call fails the test and the row says `NO-LIVE`.

### `ANSWER.md`, captures, `OUTPUT-PENDING`

- When `AnswerHeadings` is set, a **solution** must ship `ANSWER.md` (the reference answer, in the
  student format) that exists, is non-empty, has each heading line exactly, and has text under each.
  In a starter, `ANSWER.md` is the student's file: absent in the shipped tree; when present (the
  student's own run, `check.ps1`), it is graded the same way. It is never part of harness fidelity.
- `capture*.txt` / `whatif*.txt` may start with `# source: <relative path> sha256=<hex>` lines. If the
  named file's SHA-256 changed, the row fails `STALE`. Get the hash with
  `(Get-FileHash main.bicep -Algorithm SHA256).Hash.ToLower()`.
- `OUTPUT-PENDING` anywhere in an item, or in `units/`, `capstones/`, `solutions/`, `README.md`,
  `PROGRESS.md`, `docs/ROADMAP.md`, fails verify-all / lint. A `[WHATIF]` capture is real output or
  `OUTPUT-PENDING`; never invented.

## 7. verify-all rules

verify-all walks `units/`, `capstones/`, and `solutions/`. Mirrors: `units/<unit>/…` ↔
`solutions/<unit>/…`; `capstones/<cN-name>/…` ↔ `solutions/capstones/<cN-name>/…`. Recognised:
`aNN-<slug>/LESSON.md`, `eNN-<slug>/`, `drills/README.md`, `drills/rNN-<slug>/`, `lesson-demo/`,
`capstones/cN-<name>/README.md` and `eNN-<slug>/`. Anything else is a counted **SKIP** row, and any
SKIP makes the run fail (SPEC 8.5).

| Primary tag | Starter must | Solution must |
|---|---|---|
| WRITE, DRILL, MODIFY | compile; be lint- and PSRule-clean; have no `#disable-next-line` / `#disable-diagnostics`; still be missing part of its Expect* list; and **fail** Pester with an assertion (a crash is an exercise bug). Verdict: `scaffold OK: structural tests fail pending: …` | everything below |
| BUG | compile; with `ExpectDiagnostics`, fail **exactly** that set of lint + PSRule rules (Pester may also fail); without it, be clean and fail Pester | everything below |
| PREDICT, EXPLAIN, WHATIF, PORTAL, CLI | compile/parse; be clean; pass its shipped Pester test if any | everything below |
| any | manifest valid; no `OUTPUT-PENDING`; no `STALE` capture; NO-LIVE | compile; lint- and PSRule-clean; Expect* satisfied; Pester passes; `ANSWER.md` complete when `AnswerHeadings` is set; `NOTES.md` non-empty; harness byte-identical |

**Harness fidelity.** Every starter file except `ANSWER.md` must exist in the solution and be
byte-identical, except the entry file under its `StudentRegion`: `below-marker` compares start of file
through the marker line; `above-marker` compares the marker line through the end; `whole-file`
compares nothing for the entry. Extra files in the solution (`NOTES.md`, `ANSWER.md`, modules) are allowed.

**Missing solution** (any exercise or drill) and **orphan solution** both fail. **Lesson demos** pass
like a solution: with an `exercise.psd1`, the full solution rule; without one, every `.bicep` compiles
and is clean, every `*.tests.ps1` passes, every `.ps1` parses. `[LAB]` rows say `offline only; live
steps not run`; an `up.bicep` next to a LAB entry must compile and lint clean.

**Empty tree.** SPEC 7.7 says verify-all exits 0 only when at least one item was checked. Phase 1
lands before any unit, so an **empty** tree (no rows at all) exits 0 and says so. Pass
`-RequireItems` to enforce the spec rule; add it to `ci.yml` once the first unit merges (decision
for Nathan, tracked in the PR).

**Clean tree.** Builds go to stdout; Pester results go to a temp file that is deleted; selftest
checks byte-for-byte that verify-all changed nothing, and CI fails on any `git status --porcelain
--ignored` output.

## 8. Ownership reminder

Bruce owns everything in this document (`scripts/`, `lib/`, `bicepconfig.json`, `ps-rule.yaml`,
`.github/`, `.gitignore`, `.lab-env.example.json`, `solutions/`). Jack Gable owns exercise and drill
files under `units/` and `capstones/`; Monk owns `LESSON.md`, `drills/README.md`, `README.md`,
`PROGRESS.md`, `docs/ROADMAP.md` (SPEC 12.2).

## 9. Self-test coverage

`scripts/selftest.ps1` runs `scripts/selftest/AzGrinding.Tests.ps1` (template flattening incl. module
deployments and languageVersion 2.0, Expect* helpers, ids, `ANSWER.md`, marker split, az mock), then
builds one temp course tree per case from `scripts/selftest/fixtures/` and runs verify-all on it,
asserting exit code, required text, and an unchanged tree:

| Case | Proves |
|---|---|
| `empty-tree-passes` / `empty-tree-require-items` | empty tree exits 0; `-RequireItems` exits 1 |
| `write-scaffold-ok-and-solution-pass` | untouched WRITE starter is scaffold-OK, solution passes, lesson demo passes |
| `write-starter-that-passes-is-flagged` | a starter that already has the work fails |
| `write-starter-compile-error-is-exercise-bug` | a starter that does not compile is an exercise bug |
| `write-stop-line-is-rejected` | `#disable-next-line` in a starter fails |
| `dummy-resource-fails-the-sample-test` | the template harness rejects a dummy resource |
| `fidelity-harness-file-drift` / `fidelity-edit-above-marker` | harness edits in a solution fail |
| `missing-and-orphan-solutions-fail` | both fail |
| `stray-paths-are-counted-skips` | stray paths print SKIP, are counted, and fail the run |
| `bug-fails-exactly-expectdiagnostics` / `bug-wrong-expectdiagnostics-fails` | BUG passes on exactly `Azure.Storage.SecureTransfer`; a wrong list fails both ways |
| `modify-expectproperties` | MODIFY pending on `sku.name = "Standard_LRS"`, solution passes |
| `cli-drill-with-mocked-az` / `cli-drill-without-mock-is-no-live` | CLI drill against fixtures; unmocked `az` fails NO-LIVE |
| `explain-answer-pass` / `answer-missing-heading-fails` / `empty-answer-fails` | `ANSWER.md` grading |
| `whatif-real-capture-passes` / `whatif-output-pending-and-stale-fail` | capture hash check, `OUTPUT-PENDING`, `STALE` |
| `manifest-errors-fail` | unknown tag, bad `StudentRegion` |
| `only-filter-and-mirror` | `-Only` scopes the run and brings the mirrored solution |

## 10. Lab guardrails (`scripts/lab/`)

`lab-up.ps1 -Path <exercise>`, `lab-down.ps1 -Path <exercise> | -Unit <unit>`, and `lab-sweep.ps1`
are the only scripts that call Azure. Every Azure CLI call goes through one function,
`Invoke-LabAz`, which the Pester tests mock, so the guard logic is tested offline. **Agents and CI
never run these scripts live.** All three accept `-WhatIf` (dry run: the read-only guard calls run,
nothing is created or deleted) and `-EnvFile`.

### `.lab-env.json`

Copy `.lab-env.example.json` to `.lab-env.json` at the repo root (gitignored; `lint.ps1` fails if it
is ever committed). Fields:

| Field | Required | Meaning |
|---|---|---|
| `expectedTenantId` | yes | Personal MSA **Default Directory**: resource labs A00–A04 and A06–A17 |
| `expectedSubscriptionId` | yes | Personal subscription in that tenant |
| `expectedEntraTenantId` | yes | The **disposable Entra test tenant**: A05, and any script that creates or modifies Entra users, groups, guests, or directory policies. Must differ from `expectedTenantId` |
| `prefix` | no (`lagb`) | Resource-group prefix; groups are `<prefix>-<exercise-id>` |
| `location` | no (`eastus`) | Lab region |
| `owner` | no (`n8`) | `owner` tag |
| `budget` | no | `{ "name": "lagb-monthly", "amount": 25 }`: the A02 budget lab-up looks for |
| `allowedCustomDomains` | no | Verified custom domains that are yours (e.g. `skopekreep.com` if you add it to the tenant) |
| `corporatePatterns` | no | Extra substrings that mark a work tenant; `deloitte` is always built in |

The unedited example is refused (placeholder all-zero GUIDs, and the two tenants are equal).

### What the guard refuses (exit 3)

1. `.lab-env.json` missing, malformed, placeholder, or the two tenant ids equal.
2. **Scope.** `Entra` scope is unit `a05-*` (or a caller that passes `-DirectoryChange` to
   `Get-LabScope`): the active tenant must equal `expectedEntraTenantId`. `Resource` scope (every other
   unit): the active tenant must equal `expectedTenantId` **and** the subscription
   `expectedSubscriptionId`. Each refusal prints the `az login --tenant …` / `az account set …` fix.
3. **Corporate-looking tenant, in both scopes.** From `az account show` and `az account tenant list`:
   the tenant display name, default domain, any verified domain, or the signed-in user contains
   `deloitte` (or a `corporatePatterns` entry), even if listed in `allowedCustomDomains`; or the
   tenant has a verified domain that is not `*.onmicrosoft.com` and not in `allowedCustomDomains`
   (work directories always have custom domains; a personal Default Directory does not); or the
   tenant cannot be found in the tenant list.
4. **Budget gate** (`lab-up`, resource scope, every unit after A02): no positive budget named
   `budget.name` (or any, if unset) from `az consumption budget list`. `-BudgetOverride` deploys anyway
   with a loud warning (SPEC 10.3).

### What the scripts do once the guard passes

- **lab-up**: requires the `LAB` tag; creates `<prefix>-<exercise-id>` with tags `course`, `unit`,
  `exercise`, `expires` (UTC, default 8 h, `-ExpiresInHours`), `owner` (SPEC 10.2); deploys `up.bicep`
  (or the entry) with `up.bicepparam` when present. An exercise that ships `up.ps1` (A05 directory
  labs) has it run after the guard with `-Context -Tags -LabEnv -WhatIf`.
- **lab-down**: selects only resource groups tagged `course=LearnAzureByGrinding`, named `<prefix>-…`,
  with the matching `unit` (and `exercise` for `-Path`) tag; prints soft-delete / purge warnings for
  Key Vault, Managed HSM, Recovery Services, Backup vaults, Azure AI services, Log Analytics, API
  Management, App Configuration; then `az group delete --yes --no-wait`. `Remove-LabResourceGroup`
  refuses an untagged group outright. A `down.ps1` in the exercise runs instead when present.
- **lab-sweep**: list-only. Every course-tagged group and resource with type, region, `expires`,
  `EXPIRED`, and a cost-risk class (HIGH: Bastion, public IP, VM/VMSS, App Service plan, load balancer,
  Recovery Services, Firewall, VPN/App Gateway, AKS, NAT gateway; MEDIUM: disks, ACR, Container Apps
  environment, ACI, Log Analytics, DNS zones, private endpoints, Key Vault, storage), plus soft-deleted
  Key Vaults. Exit 1 when anything is left.

`scripts/lab/tests/LabGuard.Tests.ps1` (37 tests) covers every refusal above in both scopes,
including the two-tenant split, plus tagging, `-WhatIf`, budget override, unit/exercise selection,
and soft-delete warnings. It installs a global `az` that throws, so a missed mock fails the test
instead of reaching Azure.

## 11. CI

`.github/workflows/ci.yml`: `pull_request`, `push` to `main`, `workflow_dispatch`;
`permissions: contents: read`; legs `windows-pwsh` (`windows-latest`) and `ubuntu-pwsh`
(`ubuntu-latest`), `fail-fast: false`. Steps: install pins → print versions → `lint.ps1` →
`selftest.ps1` → `verify-all.ps1` → `psrule.ps1` → lab guard Pester → fail on any
`git status --porcelain --ignored` output. No secrets, no Azure sign-in; the Bicep binary is
downloaded to `$RUNNER_TEMP`, outside the checkout.

**Not added: the OIDC live-smoke workflow** (SPEC 11, approved as optional). It needs an Entra app
registration or managed identity with a federated credential for this repo, and its tenant,
subscription, and client ids as repository variables, all of which only Nathan can create. It will be a
separate `workflow_dispatch`-only file in a later PR.

## 12. Where this differs from the SPEC text, and why

| SPEC | Implemented | Why |
|---|---|---|
| 6: `scripts/lab-up.ps1`, `lab-down.ps1`, `sweep.ps1` | `scripts/lab/lab-up.ps1`, `lab-down.ps1`, `lab-sweep.ps1` | Phase 1 brief; keeps live scripts apart from offline ones |
| 4.5: course rules set to `Error` | `warning` + harness fails on warnings | `bicep build` fails on error-level linter rules, so a lint-defect `[BUG]` starter could not compile |
| 7.4: course root found by walking up to `docs/SPEC.md` | walk up to `lib/AzGrinding.psd1` (+ `bicepconfig.json` for scripts) | Works in selftest temp trees and `reps/` without copying the spec |
| 7.7: verify-all exits 0 only if at least one item was checked | empty tree exits 0; `-RequireItems` enforces the rule | No units exist yet |
| 11: PSRule via `microsoft/ps-rule` | `scripts/psrule.ps1` + verify-all, same pinned module | Tag-aware: `[BUG]` starters fail PSRule on purpose; spec allows either |
| 7.4 `Tag` (space-separated words) | `Tags` string array, first is primary | Spec v0.3 |
| 3.2: corporate detection "by domain or display name" | also refuses any non-`onmicrosoft.com` verified domain not explicitly allowed, and the signed-in user name | Stricter default; personal tenants have no custom domains unless you add one |
