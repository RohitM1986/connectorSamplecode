# Deployment Script for CRM F&O PoC Package
# PowerShell script to deploy a package on D365 F&O one-box using official tools.

param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [string]$PackagePath,

    [Parameter(Mandatory=$false)]
    [string]$ModelName = "CRMFOpoC",

    [Parameter(Mandatory=$false)]
    [bool]$SyncDatabase = $true,

    [Parameter(Mandatory=$false)]
    [string]$AOSServicePath = "C:\AOSService",

    [Parameter(Mandatory=$false)]
    [string]$SqlServer = ".",

    [Parameter(Mandatory=$false)]
    [string]$SqlDatabase = "AxDB",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CRM F&O PoC Package Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Invoke-ToolCommand {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToolPath,

        [Parameter(Mandatory=$true)]
        [string[]]$Arguments,

        [Parameter(Mandatory=$false)]
        [switch]$DryRunMode
    )

    $commandLine = "$ToolPath $($Arguments -join ' ')"
    Write-Log "Command: $commandLine"

    if ($DryRunMode) {
        Write-Log "Dry run enabled. Command not executed." "WARNING"
        return
    }

    & $ToolPath @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $commandLine"
    }
}

try {
    Write-Log "Validating package path: $PackagePath"
    if (-not (Test-Path $PackagePath)) {
        throw "Package path not found: $PackagePath"
    }

    if ($PackagePath -notmatch "\.zip$") {
        Write-Log "Package is not a .zip file. Deployable package should be a zip artifact." "WARNING"
    }

    Write-Log "Connecting to environment: $Environment"
    Write-Log "Deployment mode: One-box tool execution"
    Write-Log "Model: $ModelName"

    $normalizedAosPath = $AOSServicePath.TrimEnd('\\')
    $packagesDir = "$normalizedAosPath\\PackagesLocalDirectory"
    $axUpdateInstaller = "$packagesDir\\Bin\\AXUpdateInstaller.exe"
    $setupExe = "$packagesDir\\Bin\\Microsoft.Dynamics.AX.Deployment.Setup.exe"

    Write-Log "AXUpdateInstaller path: $axUpdateInstaller"
    Write-Log "Deployment.Setup path: $setupExe"

    if (-not $DryRun) {
        if ($PSVersionTable.Platform -and $PSVersionTable.Platform -ne "Win32NT") {
            throw "Actual deployment tool execution requires Windows one-box VM. Use -DryRun on non-Windows."
        }

        if (-not (Test-Path $axUpdateInstaller)) {
            throw "AXUpdateInstaller.exe not found at: $axUpdateInstaller"
        }

        if ($SyncDatabase -and -not (Test-Path $setupExe)) {
            throw "Microsoft.Dynamics.AX.Deployment.Setup.exe not found at: $setupExe"
        }
    }

    Write-Log "Step 1: Deploying package using AXUpdateInstaller..."
    Invoke-ToolCommand -ToolPath $axUpdateInstaller -Arguments @(
        "devinstall",
        "-package=$PackagePath"
    ) -DryRunMode:$DryRun
    Write-Log "Package deployment step completed" "SUCCESS"

    if ($SyncDatabase) {
        Write-Log "Step 2: Running database synchronization..."
        Invoke-ToolCommand -ToolPath $setupExe -Arguments @(
            "-bindir", "`"$packagesDir`"",
            "-metadatadir", "`"$packagesDir`"",
            "-sqlserver", "`"$SqlServer`"",
            "-sqldatabase", "`"$SqlDatabase`"",
            "-setupmode", "sync",
            "-syncmode", "fullall"
        ) -DryRunMode:$DryRun
        Write-Log "Database synchronization step completed" "SUCCESS"
    }
    else {
        Write-Log "Database synchronization skipped by parameter" "WARNING"
    }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Deployment command sequence completed!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Verify model/package state in Environment monitoring"
    Write-Host "2. Navigate to Organization administration > Setup > CRM Integration Parameters"
    Write-Host "3. Configure the API endpoint and authentication"
    Write-Host "4. Test the integration and batch execution"
}
catch {
    Write-Log "Deployment failed: $_" "ERROR"
    exit 1
}
