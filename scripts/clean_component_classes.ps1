$ErrorActionPreference = "Stop"

$repo = "$HOME\Desktop\anonymous-threatspider-artifact"

$componentsPath = Join-Path $repo "data\01_system_model\components.csv"
$rawClassesPath = Join-Path $repo "data\01_system_model\component_classes_raw.csv"
$outputPath = Join-Path $repo "data\01_system_model\component_classes.csv"

if (-not (Test-Path $componentsPath)) {
    throw "Missing file: $componentsPath"
}

if (-not (Test-Path $rawClassesPath)) {
    throw "Missing file: $rawClassesPath"
}

$components = Import-Csv $componentsPath

$componentIndex = @{}

foreach ($row in $components) {
    $name = ([string]$row.Component).Trim()

    if ($name) {
        $componentIndex[$name] = ([string]$row.Layer).Trim()
    }
}

# Read every line using fixed positional column names.
# This avoids problems caused by section headings and repeated headers.
$rawClasses = Import-Csv `
    -Path $rawClassesPath `
    -Header "Col1","Col2","Col3","Col4","Col5"

$cleanRows = foreach ($row in $rawClasses) {

    $componentName = ([string]$row.Col1).Trim()

    # Retain only rows whose first column exactly matches
    # one of the 34 component names.
    if ($componentIndex.ContainsKey($componentName)) {

        [PSCustomObject]@{
            Layer                         = $componentIndex[$componentName]
            Component                     = $componentName
            "Primary ThreatSpider Class"  = ([string]$row.Col2).Trim()
            "Secondary Class"             = ([string]$row.Col3).Trim()
            "Standalone Component?"       = ([string]$row.Col4).Trim()
            Notes                         = ([string]$row.Col5).Trim()
        }
    }
}

$cleanRows |
    Export-Csv `
        -Path $outputPath `
        -Delimiter ',' `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "Created: $outputPath"
Write-Host "Components in components.csv: $($components.Count)"
Write-Host "Components in component_classes.csv: $($cleanRows.Count)"

if ($cleanRows.Count -ne $components.Count) {

    Write-Warning "Component counts do not match."

    $cleanNames = @($cleanRows | ForEach-Object { $_.Component })

    $missing = $components |
        Where-Object { $_.Component -notin $cleanNames } |
        Select-Object -ExpandProperty Component

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "Missing components:"
        $missing | ForEach-Object {
            Write-Host "- $_"
        }
    }
}
else {
    Write-Host "Validation passed: component counts match."
}