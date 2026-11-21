# Selftest fixture drill: write Get-CourseGroupNames, which returns the names of the resource
# groups tagged course=LearnAzureByGrinding, using `az group list --tag ... --output json`.
Set-StrictMode -Version 3.0

# ---- Your code goes below this line. ----
function Get-CourseGroupNames {
    $json = az group list --tag course=LearnAzureByGrinding --output json
    @($json | ConvertFrom-Json | ForEach-Object name)
}
