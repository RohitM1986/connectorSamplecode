# Test Script for CRM API Integration
# PowerShell script to test the integration

param(
    [Parameter(Mandatory=$false)]
    [string]$APIEndpoint = "https://api.example.com/v1/sync",

    [Parameter(Mandatory=$false)]
    [ValidateSet("GET", "POST", "PUT", "PATCH", "DELETE")]
    [string]$APIMethod = "GET",
    
    [Parameter(Mandatory=$false)]
    [string]$APIKey = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$TestConnection = $false
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CRM API Integration Test" -ForegroundColor Cyan
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

# Test connection to API
if ($TestConnection) {
    Write-Log "Testing connection to API endpoint: $APIEndpoint"
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        if ($APIKey) {
            $headers["X-API-Key"] = $APIKey
        }
        
        $response = Invoke-WebRequest -Uri $APIEndpoint -Method GET -Headers $headers -TimeoutSec 10
        
        if ($response.StatusCode -eq 200) {
            Write-Log "API connection successful!" "SUCCESS"
            Write-Log "Response: $($response.Content)"
        } else {
            Write-Log "API returned status code: $($response.StatusCode)" "WARNING"
        }
    } catch {
        Write-Log "API connection failed: $_" "ERROR"
    }
}

# Create test payload
Write-Log "Creating test payload..."

$testPayload = @{
    requestId = [guid]::NewGuid().ToString()
    requestTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    requestType = "CustomerSync"
    customers = @(
        @{
            customerAccount = "TEST-001"
            customerName = "Test Customer Ltd"
            email = "test@example.com"
            phone = "+1-555-0123"
            address = @{
                street = "123 Test Street"
                city = "Seattle"
                state = "WA"
                zipCode = "98101"
                country = "USA"
            }
            customerGroup = "10"
            currency = "USD"
            paymentTerms = "Net30"
            isActive = $true
        }
    )
} | ConvertTo-Json -Depth 10

Write-Log "Test payload created"
Write-Host $testPayload -ForegroundColor Gray
Write-Host ""

# Send test request
if ($APIEndpoint) {
    Write-Log "Sending test request to API..."
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }

        if ($APIKey) {
            $headers["X-API-Key"] = $APIKey
        }

        if ($APIMethod -eq "GET") {
            $response = Invoke-RestMethod -Uri $APIEndpoint -Method GET -Headers $headers -TimeoutSec 30
        }
        else {
            $response = Invoke-RestMethod -Uri $APIEndpoint -Method $APIMethod -Headers $headers -Body $testPayload -TimeoutSec 30
        }
        
        Write-Log "Test request completed successfully!" "SUCCESS"
        Write-Log "Response:"
        Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor Green
        
    } catch {
        Write-Log "Test request failed: $_" "ERROR"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Log "Response body: $responseBody" "ERROR"
        }
    }
} else {
    Write-Log "Skipping API test (API endpoint not provided)" "WARNING"
    Write-Log "Use -APIEndpoint parameter to test actual API"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Test completed" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
