param(
    [string]$Profile = "ekewaka",
    [string]$PlanFile = "phase1.tfplan"
)

$ErrorActionPreference = "Stop"
$env:AWS_PROFILE = $Profile

aws sts get-caller-identity --profile $Profile

if (-not (Test-Path $PlanFile)) {
    throw "Plan file '$PlanFile' not found. Run 02-plan.ps1 first."
}

terraform apply $PlanFile
terraform output
