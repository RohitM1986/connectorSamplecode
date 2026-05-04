param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId = "dd64b6ec-0a2a-4f60-8ca1-eeaab33884d7",

    [Parameter(Mandatory = $false)]
    [string]$ClientId = "220ebf68-a86d-4392-ae38-57b2172ee3fc",

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret = [System.Environment]::GetEnvironmentVariable("D365_CLIENT_SECRET", "User"),

    [Parameter(Mandatory = $false)]
    [string]$ResourceUrl = "https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com",

    [Parameter(Mandatory = $false)]
    [string]$TokenFile = "$PSScriptRoot/current_bearer_token.txt",

    [Parameter(Mandatory = $false)]
    [switch]$Quiet,

    [Parameter(Mandatory = $false)]
    [switch]$SkipSslValidation
)

$ErrorActionPreference = 'Stop'

$tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

$body = @{
    client_id     = $ClientId
    scope         = "$ResourceUrl/.default"
    client_secret = $ClientSecret
    grant_type    = "client_credentials"
}

$tokenRequestParams = @{
    Method      = 'Post'
    Uri         = $tokenUrl
    ContentType = 'application/x-www-form-urlencoded'
    Body        = $body
}

if ($SkipSslValidation) {
    $tokenRequestParams.SkipCertificateCheck = $true
}

$tokenResponse = Invoke-RestMethod @tokenRequestParams

$accessToken = [string]$tokenResponse.access_token

if (-not $accessToken) {
    throw "Token response did not contain access_token"
}

if ($TokenFile) {
    Set-Content -Path $TokenFile -Value $accessToken -Encoding utf8
}

if (-not $Quiet) {
    Write-Host "Access Token acquired."
    if ($TokenFile) {
        Write-Host "Token saved to: $TokenFile"
    }
}

Write-Output $accessToken
