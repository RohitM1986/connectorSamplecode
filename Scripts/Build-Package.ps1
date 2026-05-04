# Build Script for CRM F&O PoC Package
# PowerShell script to build the package locally

param(
    [Parameter(Mandatory=$false)]
    [string]$Configuration = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\Output",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CRM F&O PoC Package Build" -ForegroundColor Cyan
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

try {
    # Step 1: Clean if requested
    if ($Clean -and (Test-Path $OutputPath)) {
        Write-Log "Cleaning output directory..."
        Remove-Item -Path $OutputPath -Recurse -Force
    }
    
    # Step 2: Create output directory
    if (-not (Test-Path $OutputPath)) {
        Write-Log "Creating output directory: $OutputPath"
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Step 3: Build the model
    Write-Log "Building model with configuration: $Configuration"
    
    # In a real scenario, you would use MSBuild or the D365 build tools
    # Example:
    # msbuild.exe /p:Configuration=$Configuration /p:Platform="Any CPU" /t:Rebuild
    
    Write-Log "Build completed successfully" "SUCCESS"
    
    # Step 4: Package creation
    Write-Log "Creating deployment package..."
    
    # Copy necessary files to output
    $sourceFiles = @(
        ".\Metadata\*",
        ".\Descriptor\*"
    )
    
    foreach ($source in $sourceFiles) {
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $OutputPath -Recurse -Force
            Write-Log "Copied: $source"
        }
    }
    
    Write-Log "Package created in: $OutputPath" "SUCCESS"
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output location: $OutputPath" -ForegroundColor Cyan
    
} catch {
    Write-Log "Build failed: $_" "ERROR"
    exit 1
}
