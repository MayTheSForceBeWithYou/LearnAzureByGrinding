# Single source of truth for toolchain pins. CI (.github/workflows/ci.yml) and
# scripts/install-tools.ps1 read this file; scripts/lint.ps1 checks that
# docs/AUTHORING-INFRA.md quotes the same numbers. Bumping a pin is a deliberate PR.
@{
    BicepVersion            = '0.49.2'
    PesterVersion           = '5.9.1'
    PSRuleVersion           = '2.9.0'
    PSRuleRulesAzureVersion = '1.47.0'
    # Named PSRule baseline; ps-rule.yaml maps the '@course' group to it.
    PSRuleBaseline          = 'Azure.Pillar.Security.L1'
    PowerShellMinimum       = '7.4.0'
    AzureCliMinimum         = '2.76.0'
}
