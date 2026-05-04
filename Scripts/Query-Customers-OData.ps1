param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceUrl = "https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com",

    [Parameter(Mandatory = $false)]
    [string]$BearerToken,

    [Parameter(Mandatory = $false)]
    [string]$BearerTokenFile = "$PSScriptRoot/current_bearer_token.txt",

    [Parameter(Mandatory = $false)]
    [string]$Name = "",

    [Parameter(Mandatory = $false)]
    [int]$Top = 10,

    [Parameter(Mandatory = $false)]
    [switch]$CrossCompany
)

$ErrorActionPreference = 'Stop'

function Get-TokenValue {
    param(
        [string]$InlineToken,
        [string]$TokenFile,
        [string]$BaseUrl
    )

    if ($InlineToken) {
        return $InlineToken.Trim()
    }

    $tokenScript = Join-Path $PSScriptRoot 'Get-D365-BearerToken.ps1'
    if (Test-Path $tokenScript) {
        $freshToken = & $tokenScript -ResourceUrl $BaseUrl -TokenFile $TokenFile -Quiet
        if ($freshToken) {
            return $freshToken.Trim()
        }
    }

    if (-not (Test-Path $TokenFile)) {
        throw "Bearer token not provided and token file not found: $TokenFile"
    }

    $token = (Get-Content -Raw -Path $TokenFile).Trim()
    if (-not $token) {
        throw "Token file is empty: $TokenFile"
    }

    return $token
}

$token = Get-TokenValue -InlineToken $BearerToken -TokenFile $BearerTokenFile -BaseUrl $ResourceUrl
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

$queryParts = @()
if ($CrossCompany) {
    $queryParts += 'cross-company=true'
}
if ($Top -gt 0) {
    $queryParts += "`$top=$Top"
}
if ($Name) {
    $escapedName = $Name.Replace("'", "''")
    $queryParts += "`$filter=Name eq '$escapedName'"
}

$queryString = if ($queryParts.Count -gt 0) { '?' + ($queryParts -join '&') } else { '' }
$url = "$ResourceUrl/data/Customers$queryString"

try {
    $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
    $rows = @($response.value)
}
catch {
    if (-not $Name) {
        throw
    }

    $fallbackParts = @()
    if ($CrossCompany) {
        $fallbackParts += 'cross-company=true'
    }
    $fallbackParts += "`$top=1000"

    $fallbackUrl = "$ResourceUrl/data/Customers?" + ($fallbackParts -join '&')
    $fallbackResponse = Invoke-RestMethod -Method Get -Uri $fallbackUrl -Headers $headers
    $allRows = @($fallbackResponse.value)

    $targetName = $Name.Trim().ToLowerInvariant()
    $rows = $allRows | Where-Object {
        $_.Name -and $_.Name.ToString().Trim().ToLowerInvariant() -eq $targetName
    }
}

Write-Host "Endpoint: $url"
Write-Host "Rows returned: $($rows.Count)"

if ($rows.Count -eq 0) {
    Write-Host "No matching customers found."
    exit 0
}

$rows | Select-Object CustomerAccount, Name, dataAreaId, PrimaryContactEmail, AddressCity | Format-Table -AutoSize
