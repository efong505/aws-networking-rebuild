param(
    [string]$Profile = "ekewaka"
)

$ErrorActionPreference = "Stop"
$env:AWS_PROFILE = $Profile

aws sts get-caller-identity --profile $Profile
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
