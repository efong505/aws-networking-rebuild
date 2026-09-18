param(
    [string]$Profile = "ekewaka"
)

$ErrorActionPreference = "Stop"
$env:AWS_PROFILE = $Profile

Write-Host "AWS identity (verify account before any deployment):" -ForegroundColor Cyan
aws sts get-caller-identity --profile $Profile

Write-Host "Terraform version:" -ForegroundColor Cyan
terraform version

Write-Host "Initializing Terraform..." -ForegroundColor Cyan
terraform init

Write-Host "Checking Terraform formatting..." -ForegroundColor Cyan
terraform fmt -recursive -check

Write-Host "Validating Terraform configuration..." -ForegroundColor Cyan
terraform validate

Write-Host "Preflight complete. Next step: run 02-plan.ps1 and review the plan before apply." -ForegroundColor Green
