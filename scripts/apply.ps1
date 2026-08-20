<#
Copies this starter's .pages.yml into a target dealer-template repo.
Usage: pwsh scripts/apply.ps1 -Target ../plumbing-template-1
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Target
)

if (-not (Test-Path $Target)) {
    throw "Target path '$Target' does not exist."
}

$source = Join-Path $PSScriptRoot "..\.pages.yml"
$dest = Join-Path $Target ".pages.yml"

if (Test-Path $dest) {
    $answer = Read-Host "`.pages.yml already exists at $dest. Overwrite? (y/N)"
    if ($answer -ne "y") {
        Write-Host "Aborted."
        exit 0
    }
}

Copy-Item $source $dest -Force
Write-Host "Copied .pages.yml to $dest — now fill in the components: list for this template (see README.md)."
