$ErrorActionPreference = "Stop"

$repo = "$HOME\Desktop\anonymous-threatspider-artifact"

$workbookPath = Join-Path $repo `
    "data\05_risk_outputs\rap_risk_analysis_results.xlsx"

$componentsPath = Join-Path $repo `
    "data\01_system_model\components.csv"

$outputPath = Join-Path $repo `
    "data\05_risk_outputs\risk_records.csv"

$summaryPath = Join-Path $repo `
    "data\06_summary\risk_output_summary.csv"

function Get-SourceType {
    param([string]$Identifier)

    if ($Identifier -like "AML.*") {
        return "ATLAS"
    }

    if ($Identifier -like "TID-*") {
        return "EMB3D"
    }

    if (
        $Identifier -like "EUVD-*" -or
        $Identifier -like "CVE-*"
    ) {
        return "Vulnerability"
    }

    if ($Identifier -like "T*") {
        return "ATT&CK"
    }

    return "Other"
}

function Format-NumberInvariant {
    param([double]$Value)

    return $Value.ToString(
        "0.##########",
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}

if (-not (Test-Path $workbookPath)) {
    throw "Missing workbook: $workbookPath"
}

if (-not (Test-Path $componentsPath)) {
    throw "Missing component file: $componentsPath"
}

$components = Import-Csv $componentsPath

$componentLayers = @{}

foreach ($component in $components) {
    $componentName = ([string]$component.Component).Trim()
    $componentLayer = ([string]$component.Layer).Trim()

    $componentLayers[$componentName] = $componentLayer
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$workbook = $null
$worksheet = $null
$usedRange = $null
$records = @()

try {
    $workbook = $excel.Workbooks.Open(
        $workbookPath,
        0,
        $true
    )

    $worksheet = $workbook.Worksheets.Item("Data")
    $usedRange = $worksheet.UsedRange

    $rowCount = $usedRange.Rows.Count
    $columnCount = $usedRange.Columns.Count
    $values = $usedRange.Value2

    if ($columnCount -ne 16) {
        throw "Expected 16 columns in Data sheet, found $columnCount."
    }

    $expectedHeaders = @(
        "ID",
        "Project",
        "Batch Number",
        "ComponentID",
        "Component Name",
        "MITRE ID",
        "Consequence",
        "Likelihood",
        "Impact",
        "Detectability",
        "Unmitigated Risk",
        "Residual Risk",
        "Tolerable",
        "Added By",
        "Date Added",
        "SortKey"
    )

    for ($column = 1; $column -le 16; $column++) {
        $actualHeader = ([string]$values[1, $column]).Trim()
        $expectedHeader = $expectedHeaders[$column - 1]

        if ($actualHeader -ne $expectedHeader) {
            throw "Unexpected header in column $column. Expected '$expectedHeader', found '$actualHeader'."
        }
    }

    for ($row = 2; $row -le $rowCount; $row++) {

        $componentName = ([string]$values[$row, 5]).Trim()

        if (-not $componentName) {
            continue
        }

        if (-not $componentLayers.ContainsKey($componentName)) {
            throw "Unknown component in risk data: $componentName"
        }

        $identifier = ([string]$values[$row, 6]).Trim()

        $records += [PSCustomObject]@{
            record_id          = [int]$values[$row, 1]
            project_id         = [int]$values[$row, 2]
            batch_number       = [int]$values[$row, 3]
            layer              = $componentLayers[$componentName]
            component_id       = [int]$values[$row, 4]
            component_name     = $componentName
            threat_or_vuln_id  = $identifier
            source_type        = Get-SourceType $identifier
            consequence        = ([string]$values[$row, 7]).Trim()
            likelihood         = [double]$values[$row, 8]
            impact             = [double]$values[$row, 9]
            detectability      = [double]$values[$row, 10]
            unmitigated_risk   = [double]$values[$row, 11]
            residual_risk      = [double]$values[$row, 12]
            tolerable_flag     = [int]$values[$row, 13]
        }
    }
}
finally {
    if ($null -ne $usedRange) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $usedRange
        ) | Out-Null
    }

    if ($null -ne $worksheet) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $worksheet
        ) | Out-Null
    }

    if ($null -ne $workbook) {
        $workbook.Close($false)

        [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
            $workbook
        ) | Out-Null
    }

    $excel.Quit()

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject(
        $excel
    ) | Out-Null

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

if ($records.Count -ne 1513) {
    throw "Expected 1513 risk records, found $($records.Count)."
}

$distinctRecordIds = @(
    $records |
    Select-Object -ExpandProperty record_id -Unique
)

if ($distinctRecordIds.Count -ne 1513) {
    throw "Duplicate record IDs detected."
}

$distinctComponents = @(
    $records |
    Select-Object -ExpandProperty component_name -Unique
)

if ($distinctComponents.Count -ne 34) {
    throw "Expected 34 components, found $($distinctComponents.Count)."
}

$projects = @(
    $records |
    Select-Object -ExpandProperty project_id -Unique
)

if (
    $projects.Count -ne 1 -or
    $projects[0] -ne 2
) {
    throw "Unexpected project values."
}

$batches = @(
    $records |
    Select-Object -ExpandProperty batch_number -Unique
)

if (
    $batches.Count -ne 1 -or
    $batches[0] -ne 12
) {
    throw "Unexpected batch values."
}

$invalidUnmitigated = @(
    $records |
    Where-Object {
        $expected = $_.likelihood * $_.impact

        [math]::Abs(
            $expected - $_.unmitigated_risk
        ) -gt 0.0001
    }
)

if ($invalidUnmitigated.Count -gt 0) {
    throw "Invalid unmitigated-risk calculations detected."
}

$invalidResidual = @(
    $records |
    Where-Object {
        $expected = $_.unmitigated_risk * $_.detectability

        [math]::Abs(
            $expected - $_.residual_risk
        ) -gt 0.0001
    }
)

if ($invalidResidual.Count -gt 0) {
    throw "Invalid residual-risk calculations detected."
}

$tolerableCount = @(
    $records |
    Where-Object { $_.tolerable_flag -eq 1 }
).Count

$nonTolerableCount = @(
    $records |
    Where-Object { $_.tolerable_flag -eq 0 }
).Count

if (
    $tolerableCount -ne 1484 -or
    $nonTolerableCount -ne 29
) {
    throw "Unexpected tolerability distribution."
}

$attackCount = @(
    $records |
    Where-Object { $_.source_type -eq "ATT&CK" }
).Count

$emb3dCount = @(
    $records |
    Where-Object { $_.source_type -eq "EMB3D" }
).Count

$atlasCount = @(
    $records |
    Where-Object { $_.source_type -eq "ATLAS" }
).Count

$vulnerabilityCount = @(
    $records |
    Where-Object { $_.source_type -eq "Vulnerability" }
).Count

if (
    $attackCount -ne 964 -or
    $emb3dCount -ne 441 -or
    $atlasCount -ne 48 -or
    $vulnerabilityCount -ne 60
) {
    throw "Unexpected source-type distribution."
}

$exportRecords = foreach ($record in $records) {

    $tolerability = if ($record.tolerable_flag -eq 1) {
        "Tolerable"
    }
    else {
        "Non-tolerable"
    }

    [PSCustomObject]@{
        record_id         = $record.record_id
        project_id        = $record.project_id
        batch_number      = $record.batch_number
        layer             = $record.layer
        component_id      = $record.component_id
        component_name    = $record.component_name
        threat_or_vuln_id = $record.threat_or_vuln_id
        source_type       = $record.source_type
        consequence       = $record.consequence
        likelihood        = Format-NumberInvariant $record.likelihood
        impact            = Format-NumberInvariant $record.impact
        detectability     = Format-NumberInvariant $record.detectability
        unmitigated_risk  = Format-NumberInvariant $record.unmitigated_risk
        residual_risk     = Format-NumberInvariant $record.residual_risk
        tolerable_flag    = $record.tolerable_flag
        tolerability      = $tolerability
    }
}

$exportRecords |
    Export-Csv `
        -Path $outputPath `
        -Delimiter ',' `
        -NoTypeInformation `
        -Encoding UTF8

$averageUnmitigated = (
    $records |
    Measure-Object -Property unmitigated_risk -Average
).Average

$averageResidual = (
    $records |
    Measure-Object -Property residual_risk -Average
).Average

$summary = @(
    [PSCustomObject]@{
        metric = "Risk records"
        value  = "1513"
    }
    [PSCustomObject]@{
        metric = "Components represented"
        value  = "34"
    }
    [PSCustomObject]@{
        metric = "Batch number"
        value  = "12"
    }
    [PSCustomObject]@{
        metric = "Average unmitigated risk"
        value  = Format-NumberInvariant $averageUnmitigated
    }
    [PSCustomObject]@{
        metric = "Average residual risk"
        value  = Format-NumberInvariant $averageResidual
    }
    [PSCustomObject]@{
        metric = "Tolerable records"
        value  = "$tolerableCount"
    }
    [PSCustomObject]@{
        metric = "Non-tolerable records"
        value  = "$nonTolerableCount"
    }
    [PSCustomObject]@{
        metric = "ATT&CK records"
        value  = "$attackCount"
    }
    [PSCustomObject]@{
        metric = "EMB3D records"
        value  = "$emb3dCount"
    }
    [PSCustomObject]@{
        metric = "ATLAS records"
        value  = "$atlasCount"
    }
    [PSCustomObject]@{
        metric = "Vulnerability records"
        value  = "$vulnerabilityCount"
    }
)

$summary |
    Export-Csv `
        -Path $summaryPath `
        -Delimiter ',' `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "RISK-RECORD VALIDATION PASSED"
Write-Host ""
Write-Host "Risk records: 1513"
Write-Host "Components represented: 34"
Write-Host "Project: 2"
Write-Host "Batch: 12"
Write-Host "Tolerable: 1484"
Write-Host "Non-tolerable: 29"
Write-Host "ATT&CK: 964"
Write-Host "EMB3D: 441"
Write-Host "ATLAS: 48"
Write-Host "Vulnerability: 60"
Write-Host (
    "Average unmitigated risk: {0:N3}" -f
    $averageUnmitigated
)
Write-Host (
    "Average residual risk: {0:N3}" -f
    $averageResidual
)
Write-Host ""
Write-Host "Created:"
Write-Host $outputPath
Write-Host $summaryPath
