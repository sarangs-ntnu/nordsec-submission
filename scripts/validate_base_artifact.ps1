$ErrorActionPreference = "Stop"

$repo = "$HOME\Desktop\anonymous-threatspider-artifact"
$validLayers = @("Layer 1", "Layer 2", "Layer 3")

function Clean-And-Load {
    param(
        [string]$RelativePath,
        [int]$ExpectedCount
    )

    $path = Join-Path $repo $RelativePath

    if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }

    $rows = @(
        Import-Csv $path |
        Where-Object {
            $layer = ([string]$_.Layer).Trim()
            $layer -in $validLayers
        }
    )

    $rows |
        Export-Csv `
            -Path $path `
            -Delimiter ',' `
            -NoTypeInformation `
            -Encoding UTF8

    if ($rows.Count -ne $ExpectedCount) {
        throw "$RelativePath expected $ExpectedCount rows, found $($rows.Count)."
    }

    Write-Host "Validated: $RelativePath [$($rows.Count) rows]"
    return $rows
}

function Assert-KnownComponents {
    param(
        [array]$Rows,
        [string]$ColumnName,
        [hashtable]$ComponentIndex,
        [string]$FileName
    )

    $unknown = @(
        $Rows |
        ForEach-Object {
            $name = ([string]$_.$ColumnName).Trim()

            if ($name -and -not $ComponentIndex.ContainsKey($name)) {
                $name
            }
        } |
        Sort-Object -Unique
    )

    if ($unknown.Count -gt 0) {
        Write-Host ""
        Write-Host "Unknown components in ${FileName}:"
        $unknown | ForEach-Object { Write-Host "- $_" }

        throw "Unknown component references detected."
    }
}

Write-Host ""
Write-Host "Cleaning and validating base artifact..."
Write-Host ""

$components = Clean-And-Load `
    "data\01_system_model\components.csv" 34

$classes = Clean-And-Load `
    "data\01_system_model\component_classes.csv" 34

$relations = Clean-And-Load `
    "data\01_system_model\system_graph_relations.csv" 41

$attacks = Clean-And-Load `
    "data\02_cti_mappings\component_attack_mapping.csv" 85

$mitre = Clean-And-Load `
    "data\02_cti_mappings\attack_mitre_mapping.csv" 46

$vulnerabilities = Clean-And-Load `
    "data\02_cti_mappings\component_vulnerability_mapping.csv" 63

$mitigations = Clean-And-Load `
    "data\03_mitigations\existing_mitigations.csv" 34

$consequences = Clean-And-Load `
    "data\04_risk_inputs\consequence_mapping.csv" 66

# Build component lookup.
$componentIndex = @{}

foreach ($row in $components) {
    $name = ([string]$row.Component).Trim()

    if ($componentIndex.ContainsKey($name)) {
        throw "Duplicate component: $name"
    }

    $componentIndex[$name] = $true
}

# Validate the expected layered decomposition.
$layer1 = @($components | Where-Object { $_.Layer -eq "Layer 1" }).Count
$layer2 = @($components | Where-Object { $_.Layer -eq "Layer 2" }).Count
$layer3 = @($components | Where-Object { $_.Layer -eq "Layer 3" }).Count

if ($layer1 -ne 22 -or $layer2 -ne 8 -or $layer3 -ne 4) {
    throw "Unexpected component distribution: Layer 1=$layer1, Layer 2=$layer2, Layer 3=$layer3"
}

Write-Host "Component distribution validated: 22 / 8 / 4"

# Validate component references.
Assert-KnownComponents `
    $classes "Component" $componentIndex "component_classes.csv"

Assert-KnownComponents `
    $attacks "Component" $componentIndex "component_attack_mapping.csv"

Assert-KnownComponents `
    $vulnerabilities "Component" $componentIndex "component_vulnerability_mapping.csv"

Assert-KnownComponents `
    $mitigations "Component" $componentIndex "existing_mitigations.csv"

Assert-KnownComponents `
    $consequences "Component" $componentIndex "consequence_mapping.csv"

Assert-KnownComponents `
    $relations "Source Component" $componentIndex "system_graph_relations.csv"

Assert-KnownComponents `
    $relations "Target Component" $componentIndex "system_graph_relations.csv"

Write-Host "All component references validated."

# Verify that class assignment covers exactly the same 34 components.
$classNames = @(
    $classes |
    Select-Object -ExpandProperty Component |
    ForEach-Object { ([string]$_).Trim() }
)

$missingClasses = @(
    $components |
    Where-Object { $_.Component -notin $classNames } |
    Select-Object -ExpandProperty Component
)

if ($missingClasses.Count -gt 0) {
    throw "Missing class assignments: $($missingClasses -join ', ')"
}

# Create summary table.
$summaryFolder = Join-Path $repo "data\06_summary"
New-Item -ItemType Directory -Force -Path $summaryFolder | Out-Null

$summary = @(
    [PSCustomObject]@{
        Dataset = "Components"
        Records = $components.Count
    }
    [PSCustomObject]@{
        Dataset = "Component class assignments"
        Records = $classes.Count
    }
    [PSCustomObject]@{
        Dataset = "System graph relations"
        Records = $relations.Count
    }
    [PSCustomObject]@{
        Dataset = "Component-to-attack mappings"
        Records = $attacks.Count
    }
    [PSCustomObject]@{
        Dataset = "Attack-to-MITRE mappings"
        Records = $mitre.Count
    }
    [PSCustomObject]@{
        Dataset = "Component-to-vulnerability mappings"
        Records = $vulnerabilities.Count
    }
    [PSCustomObject]@{
        Dataset = "Existing mitigations"
        Records = $mitigations.Count
    }
    [PSCustomObject]@{
        Dataset = "Consequence mappings"
        Records = $consequences.Count
    }
)

$summary |
    Export-Csv `
        -Path (Join-Path $summaryFolder "base_artifact_counts.csv") `
        -Delimiter ',' `
        -NoTypeInformation `
        -Encoding UTF8

# Raw intermediate file is no longer needed after successful validation.
$rawClassFile = Join-Path $repo `
    "data\01_system_model\component_classes_raw.csv"

if (Test-Path $rawClassFile) {
    Remove-Item $rawClassFile -Force
    Write-Host "Removed intermediate file: component_classes_raw.csv"
}

Write-Host ""
Write-Host "BASE ARTIFACT VALIDATION PASSED"
Write-Host ""
Write-Host "Components: 34"
Write-Host "Layer distribution: 22 / 8 / 4"
Write-Host "System graph relations: 41"
Write-Host "Component-to-attack mappings: 85"
Write-Host "Attack-to-MITRE mappings: 46"
Write-Host "Component-to-vulnerability mappings: 63"
Write-Host "Existing mitigations: 34"
Write-Host "Consequence mappings: 66"



