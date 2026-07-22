$ErrorActionPreference = "Stop"

$repo = "$HOME\Desktop\anonymous-threatspider-artifact"

$workbookPath = Join-Path $repo `
    "data\03_mitigations\component_specific_mitigations.xlsx"

$componentsPath = Join-Path $repo `
    "data\01_system_model\components.csv"

$outputPath = Join-Path $repo `
    "data\03_mitigations\component_specific_mitigations.csv"

if (-not (Test-Path $workbookPath)) {
    throw "Missing workbook: $workbookPath"
}

if (-not (Test-Path $componentsPath)) {
    throw "Missing component list: $componentsPath"
}

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$workbook = $null
$worksheet = $null
$usedRange = $null

try {
    $workbook = $excel.Workbooks.Open($workbookPath, 0, $true)
    $worksheet = $workbook.Worksheets.Item("Mitigations")
    $usedRange = $worksheet.UsedRange

    $rowCount = $usedRange.Rows.Count
    $columnCount = $usedRange.Columns.Count
    $values = $usedRange.Value2

    if ($columnCount -ne 7) {
        throw "Expected 7 columns, found $columnCount."
    }

    $expectedHeaders = @(
        "Layer",
        "Component",
        "Matrix",
        "Mitigation",
        "Coverage",
        "Efficiency (%)",
        "Comment"
    )

    for ($column = 1; $column -le 7; $column++) {
        $actualHeader = ([string]$values[1, $column]).Trim()
        $expectedHeader = $expectedHeaders[$column - 1]

        if ($actualHeader -ne $expectedHeader) {
            throw "Unexpected header in column $column. Expected '$expectedHeader', found '$actualHeader'."
        }
    }

    $records = @()

    for ($row = 2; $row -le $rowCount; $row++) {
        $component = ([string]$values[$row, 2]).Trim()

        if (-not $component) {
            continue
        }

        $records += [PSCustomObject]@{
            Layer           = ([string]$values[$row, 1]).Trim()
            Component       = $component
            Matrix          = ([string]$values[$row, 3]).Trim()
            Mitigation      = ([string]$values[$row, 4]).Trim()
            Coverage        = ([string]$values[$row, 5]).Trim()
            "Efficiency (%)" = [int]$values[$row, 6]
            Comment         = ([string]$values[$row, 7]).Trim()
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

# Validate record count.
if ($records.Count -ne 212) {
    throw "Expected 212 mitigation records, found $($records.Count)."
}

# Validate components.
$components = Import-Csv $componentsPath
$validComponentNames = @(
    $components |
    Select-Object -ExpandProperty Component
)

$unknownComponents = @(
    $records |
    Where-Object {
        $_.Component -notin $validComponentNames
    } |
    Select-Object -ExpandProperty Component -Unique
)

if ($unknownComponents.Count -gt 0) {
    throw "Unknown components found: $($unknownComponents -join ', ')"
}

$distinctComponents = @(
    $records |
    Select-Object -ExpandProperty Component -Unique
)

if ($distinctComponents.Count -ne 34) {
    throw "Expected 34 represented components, found $($distinctComponents.Count)."
}

# Validate layers.
$layer1 = @(
    $records |
    Where-Object { $_.Layer -eq "Layer 1" }
).Count

$layer2 = @(
    $records |
    Where-Object { $_.Layer -eq "Layer 2" }
).Count

$layer3 = @(
    $records |
    Where-Object { $_.Layer -eq "Layer 3" }
).Count

if ($layer1 -ne 132 -or $layer2 -ne 54 -or $layer3 -ne 26) {
    throw "Unexpected layer distribution: Layer 1=$layer1, Layer 2=$layer2, Layer 3=$layer3"
}

# Validate matrices.
$ics = @(
    $records |
    Where-Object { $_.Matrix -eq "ICS" }
).Count

$emb3d = @(
    $records |
    Where-Object { $_.Matrix -eq "EMB3D" }
).Count

$atlas = @(
    $records |
    Where-Object { $_.Matrix -eq "ATLAS" }
).Count

if ($ics -ne 94 -or $emb3d -ne 87 -or $atlas -ne 31) {
    throw "Unexpected matrix distribution: ICS=$ics, EMB3D=$emb3d, ATLAS=$atlas"
}

# Validate coverage.
$invalidCoverage = @(
    $records |
    Where-Object { $_.Coverage -ne "Yes" }
)

if ($invalidCoverage.Count -gt 0) {
    throw "Found mitigation records whose Coverage value is not Yes."
}

# Validate efficiency scale.
$validEfficiencyValues = @(25, 50, 75, 100)

$invalidEfficiency = @(
    $records |
    Where-Object {
        $_."Efficiency (%)" -notin $validEfficiencyValues
    }
)

if ($invalidEfficiency.Count -gt 0) {
    throw "Invalid mitigation-efficiency values detected."
}

# Validate required text fields.
$incompleteRecords = @(
    $records |
    Where-Object {
        -not $_.Layer -or
        -not $_.Component -or
        -not $_.Matrix -or
        -not $_.Mitigation -or
        -not $_.Comment
    }
)

if ($incompleteRecords.Count -gt 0) {
    throw "Found incomplete mitigation records."
}

# Validate exact duplicates.
$duplicates = @(
    $records |
    Group-Object Layer, Component, Matrix, Mitigation, Coverage, "Efficiency (%)", Comment |
    Where-Object { $_.Count -gt 1 }
)

if ($duplicates.Count -gt 0) {
    throw "Found $($duplicates.Count) duplicate mitigation record group(s)."
}

# Export the machine-readable CSV.
$records |
    Export-Csv `
        -Path $outputPath `
        -Delimiter ',' `
        -NoTypeInformation `
        -Encoding UTF8

$averageEfficiency = (
    $records |
    Measure-Object -Property "Efficiency (%)" -Average
).Average

Write-Host ""
Write-Host "COMPONENT-SPECIFIC MITIGATION VALIDATION PASSED"
Write-Host ""
Write-Host "Mitigation records: 212"
Write-Host "Components represented: 34"
Write-Host "Layer distribution: 132 / 54 / 26"
Write-Host "Matrix distribution: ICS=94, EMB3D=87, ATLAS=31"
Write-Host ("Average efficiency: {0:N2}%" -f $averageEfficiency)
Write-Host "Duplicate records: 0"
Write-Host ""
Write-Host "Created:"
Write-Host $outputPath
