param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceUrl = "https://vtx-sandbox54c04b894a05938fdevaos.axcloud.dynamics.com",

    [Parameter(Mandatory = $false)]
    [string]$BearerToken,

    [Parameter(Mandatory = $false)]
    [string]$BearerTokenFile = "$PSScriptRoot/current_bearer_token.txt",

    [Parameter(Mandatory = $false)]
    [switch]$MetadataOnly,

    [Parameter(Mandatory = $false)]
    [switch]$SkipSslValidation
)

$ErrorActionPreference = 'Stop'

function Get-TokenValue {
    param(
        [string]$InlineToken,
        [string]$TokenFile,
        [string]$BaseUrl,
        [bool]$SkipSsl
    )

    if ($InlineToken) {
        return $InlineToken.Trim()
    }

    $tokenScript = Join-Path $PSScriptRoot 'Get-D365-BearerToken.ps1'
    if (Test-Path $tokenScript) {
        $tokenArgs = @{
            ResourceUrl = $BaseUrl
            TokenFile   = $TokenFile
            Quiet       = $true
        }

        if ($SkipSsl) {
            $tokenArgs.SkipSslValidation = $true
        }

        $freshToken = & $tokenScript @tokenArgs
        if ($freshToken) {
            return $freshToken.Trim()
        }
    }

    if (-not (Test-Path $TokenFile)) {
        throw "Bearer token not provided and token file not found: $TokenFile"
    }

    $tokenFromFile = (Get-Content -Raw -Path $TokenFile).Trim()
    if (-not $tokenFromFile) {
        throw "Token file is empty: $TokenFile"
    }

    return $tokenFromFile
}

function Get-Headers {
    param([string]$Token)

    return @{
        Authorization = "Bearer $Token"
        "Content-Type" = "application/json"
    }
}

function Get-ServiceDocumentTables {
    param(
        [string]$BaseUrl,
        [hashtable]$Headers,
        [bool]$SkipSsl
    )

    $serviceDocUrl = "$BaseUrl/data"
    $requestParams = @{
        Method  = 'Get'
        Uri     = $serviceDocUrl
        Headers = $Headers
    }

    if ($SkipSsl) {
        $requestParams.SkipCertificateCheck = $true
    }

    $serviceDoc = Invoke-RestMethod @requestParams

    if (-not $serviceDoc.value) {
        return @()
    }

    return $serviceDoc.value |
        Select-Object name, kind, url |
        Sort-Object name
}

function Get-MetadataTables {
    param(
        [string]$BaseUrl,
        [hashtable]$Headers,
        [bool]$SkipSsl
    )

    $metadataUrl = "$BaseUrl/data/\$metadata"
    $requestParams = @{
        Method  = 'Get'
        Uri     = $metadataUrl
        Headers = $Headers
    }

    if ($SkipSsl) {
        $requestParams.SkipCertificateCheck = $true
    }

    [xml]$metadataXml = Invoke-RestMethod @requestParams

    $ns = New-Object System.Xml.XmlNamespaceManager($metadataXml.NameTable)
    $ns.AddNamespace("edmx", "http://docs.oasis-open.org/odata/ns/edmx")
    $ns.AddNamespace("edm", "http://docs.oasis-open.org/odata/ns/edm")

    $entitySetNodes = $metadataXml.SelectNodes("//edm:EntityContainer/edm:EntitySet", $ns)

    $result = foreach ($node in $entitySetNodes) {
        [PSCustomObject]@{
            name       = $node.Name
            kind       = "EntitySet"
            url        = $node.Name
            entityType = $node.EntityType
        }
    }

    return $result | Sort-Object name
}

try {
    $token = Get-TokenValue -InlineToken $BearerToken -TokenFile $BearerTokenFile -BaseUrl $ResourceUrl -SkipSsl $SkipSslValidation.IsPresent
    $headers = Get-Headers -Token $token

    Write-Host "Dynamics URL: $ResourceUrl"
    Write-Host "Auth: Bearer token loaded"

    if ($MetadataOnly) {
        $tables = Get-MetadataTables -BaseUrl $ResourceUrl -Headers $headers -SkipSsl $SkipSslValidation.IsPresent
        Write-Host "Source: OData metadata"
    }
    else {
        try {
            $tables = Get-ServiceDocumentTables -BaseUrl $ResourceUrl -Headers $headers -SkipSsl $SkipSslValidation.IsPresent
            if (-not $tables -or $tables.Count -eq 0) {
                Write-Host "Service document returned no entity sets. Falling back to metadata..."
                $tables = Get-MetadataTables -BaseUrl $ResourceUrl -Headers $headers -SkipSsl $SkipSslValidation.IsPresent
                Write-Host "Source: OData metadata"
            }
            else {
                Write-Host "Source: OData service document"
            }
        }
        catch {
            Write-Host "Service document read failed. Falling back to metadata..."
            $tables = Get-MetadataTables -BaseUrl $ResourceUrl -Headers $headers -SkipSsl $SkipSslValidation.IsPresent
            Write-Host "Source: OData metadata"
        }
    }

    Write-Host "Total available tables/entities: $($tables.Count)"
    $tables | Format-Table -AutoSize
}
catch {
    Write-Error "Failed to list F&O tables/entities: $($_.Exception.Message)"
    exit 1
}
