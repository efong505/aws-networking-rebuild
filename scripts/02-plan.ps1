param(
    [string]$Profile = "ekewaka",
    [string]$OutFile = "phase1.tfplan"
)

$ErrorActionPreference = "Stop"
$env:AWS_PROFILE = $Profile

aws sts get-caller-identity --profile $Profile
terraform fmt -recursive
terraform validate
terraform plan -out $OutFile
