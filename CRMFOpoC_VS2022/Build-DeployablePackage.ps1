<#
.SYNOPSIS
    Builds the CRMFOpoC model and creates a D365 F&O deployable package.

.DESCRIPTION
    Run this script on a D365 Finance & Operations developer VM.
    It compiles the model with MSBuild and then produces a deployable package
    (.zip) that can be uploaded to LCS or applied directly to an environment.

.PARAMETER Configuration
    MSBuild configuration. Defaults to Release.

.PARAMETER OutputPath
    Folder where the final deployable package zip is written.
    Defaults to .\DeployablePackage next to this script.

.PARAMETER PackagesLocalDir
    Root packages directory on the dev VM.
    Defaults to K:\AosService\PackagesLocalDirectory.

.EXAMPLE
    .\Build-DeployablePackage.ps1
    .\Build-DeployablePackage.ps1 -OutputPath "C:\Temp\Output" -Configuration Debug
#>

[CmdletBinding()]
param(
    [string]$Configuration    = "Release",
    [string]$OutputPath       = "$PSScriptRoot\DeployablePackage",
    [string]$PackagesLocalDir = "K:\AosService\PackagesLocalDirectory"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ModelName   = "CRMFOpoC"
$SolutionFile = "$PSScriptRoot\$ModelName.sln"

# ---------------------------------------------------------------------------
# 1. Locate MSBuild (VS 2022)
# ---------------------------------------------------------------------------
$msbuild = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
    -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe 2>$null |
    Select-Object -First 1

if (-not $msbuild -or -not (Test-Path $msbuild)) {
    # Fallback to well-known VS 2022 path
    $msbuild = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
    if (-not (Test-Path $msbuild)) {
        $msbuild = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    }
}

if (-not (Test-Path $msbuild)) {
    throw "MSBuild not found. Ensure Visual Studio 2022 with D365 F&O developer tools is installed."
}

Write-Host "Using MSBuild: $msbuild" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Build the solution
# ---------------------------------------------------------------------------
Write-Host "`n[1/3] Building $ModelName ($Configuration)..." -ForegroundColor Green

$buildArgs = @(
    $SolutionFile
    "/p:Configuration=$Configuration"
    "/p:Platform=`"Any CPU`""
    "/t:Build"
    "/m"          # parallel build
    "/nologo"
    "/verbosity:minimal"
)

& $msbuild @buildArgs
if ($LASTEXITCODE -ne 0) {
    throw "MSBuild failed with exit code $LASTEXITCODE."
}

Write-Host "Build succeeded." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Locate the Dynamics CreateDeployablePackage script
# ---------------------------------------------------------------------------
Write-Host "`n[2/3] Locating package creation tools..." -ForegroundColor Green

$createPackageScript = "$PackagesLocalDir\bin\CreateDeployablePackage.ps1"

if (-not (Test-Path $createPackageScript)) {
    # Also check the AOS service folder layout used in newer builds
    $createPackageScript = "K:\AosService\webroot\bin\CreateDeployablePackage.ps1"
}

if (-not (Test-Path $createPackageScript)) {
    Write-Warning "CreateDeployablePackage.ps1 not found at expected locations."
    Write-Warning "Ensure the AOS service binaries are present on this machine."
    Write-Warning "Expected location: $PackagesLocalDir\bin\CreateDeployablePackage.ps1"
    exit 1
}

Write-Host "Found: $createPackageScript" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 4. Create the deployable package
# ---------------------------------------------------------------------------
Write-Host "`n[3/3] Creating deployable package..." -ForegroundColor Green

New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$packageZip = "$OutputPath\${ModelName}_${timestamp}.zip"

& $createPackageScript `
    -BuildModuleToPackage $ModelName `
    -SourcePath $PackagesLocalDir `
    -DestinationPath $packageZip

if ($LASTEXITCODE -ne 0) {
    throw "Package creation failed with exit code $LASTEXITCODE."
}

Write-Host "`nDeployable package created:" -ForegroundColor Green
Write-Host "  $packageZip" -ForegroundColor Yellow
Write-Host "`nUpload this file to LCS Asset Library (Deployable Package) to deploy it."
