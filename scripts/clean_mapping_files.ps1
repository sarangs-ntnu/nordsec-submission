$ErrorActionPreference = "Stop"

$repo = "$HOME\Desktop\anonymous-threatspider-artifact"

function Clean-MappingCsv {
    param(
        [string]$RelativePath,
        [string[]]$OutputHeaders,
        [int]$ExpectedCount
    )

    $path = Join-Path $repo $RelativePath
    $tempPath = "$path.temp"

    if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }

    Write-Host ""
    Write-Host "Cleaning: $RelativePath"

    # Read all rows using fixed temporary column names.
    # This safely ignores title rows, blank rows and repeated headers.
    $rawRows = Import-Csv `
        -Path $path `
        -Header "Col1","Col2","Col3","Col4","Col5"

    $cleanRows = foreach ($row in $rawRows) {

        $layer = ([string]$row.Col1).Trim()

        if ($layer -in @("Layer 1", "Layer 2", "Layer 3")) {

            $result = [ordered]@{}

            $result[$OutputHeaders[0]] = $layer
            $result[$OutputHeaders[1]] = ([string]$row.Col2).Trim()
            $result[$OutputHeaders[2]] = ([string]$row.Col3).Trim()
            $result[$OutputHeaders[3]] = ([string]$row.Col4).Trim()
            $result[$OutputHeaders[4]] = ([string]$row.Col5).Trim()

            [PSCustomObject]$result
        }
    }

    $cleanRows |
        Export-Csv `
            -Path $tempPath `
            -Delimiter ',' `
            -NoTypeInformation `
            -Encoding UTF8

    Move-Item `
        -Path $tempPath `
        -Destination $path `
        -Force

    $layer1 = @($cleanRows | Where-Object { $_.Layer -eq "Layer 1" }).Count
    $layer2 = @($cleanRows | Where-Object { $_.Layer -eq "Layer 2" }).Count
    $layer3 = @($cleanRows | Where-Object { $_.Layer -eq "Layer 3" }).Count

    Write-Host "Rows: $($cleanRows.Count)"
    Write-Host "Layer 1: $layer1"
    Write-Host "Layer 2: $layer2"
    Write-Host "Layer 3: $layer3"

    if ($cleanRows.Count -eq $ExpectedCount) {
        Write-Host "Validation passed."
    }
    else {
        Write-Warning "Expected $ExpectedCount rows, found $($cleanRows.Count)."
    }
}

Clean-MappingCsv `
    -RelativePath "data\02_cti_mappings\component_attack_mapping.csv" `
    -OutputHeaders @(
        "Layer",
        "Component",
        "Relevant Attack Type",
        "Short Rationale",
        "Priority for Pilot"
    ) `
    -ExpectedCount 80

Clean-MappingCsv `
    -RelativePath "data\02_cti_mappings\attack_mitre_mapping.csv" `
    -OutputHeaders @(
        "Layer",
        "Attack Type",
        "Candidate MITRE Framework",
        "Candidate Technique / Mapping",
        "Notes"
    ) `
    -ExpectedCount 46

Clean-MappingCsv `
    -RelativePath "data\02_cti_mappings\component_vulnerability_mapping.csv" `
    -OutputHeaders @(
        "Layer",
        "Component",
        "Relevant Vulnerability / Weakness",
        "Short Rationale",
        "Priority for Pilot"
    ) `
    -ExpectedCount 63

Write-Host ""
Write-Host "All mapping CSV files were cleaned successfully."