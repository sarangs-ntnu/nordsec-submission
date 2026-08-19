$ErrorActionPreference = "Stop"

$repo = "$HOME\Desktop\anonymous-threatspider-artifact"

$componentsPath = Join-Path $repo `
    "data\01_system_model\components.csv"

$relationsPath = Join-Path $repo `
    "data\01_system_model\system_graph_relations.csv"

$snapshotPath = Join-Path $repo `
    "evidence\system_graph_2_database_snapshot.csv"

$backupPath = Join-Path $repo `
    "evidence\system_graph_relations_before_reconciliation.csv"

if (-not (Test-Path $componentsPath)) {
    throw "Missing components file: $componentsPath"
}

if (-not (Test-Path $relationsPath)) {
    throw "Missing canonical relations file: $relationsPath"
}

if (-not (Test-Path $snapshotPath)) {
    throw "Missing database snapshot: $snapshotPath"
}

Copy-Item `
    -Path $relationsPath `
    -Destination $backupPath `
    -Force

$components = @(Import-Csv $componentsPath)
$snapshot = @(Import-Csv $snapshotPath)

if ($components.Count -ne 34) {
    throw "Expected 34 components, found $($components.Count)."
}

if ($snapshot.Count -ne 41) {
    throw "Expected 41 database relations, found $($snapshot.Count)."
}

$layerMap = @{}

foreach ($component in $components) {
    $name = ([string]$component.Component).Trim()
    $layer = ([string]$component.Layer).Trim()

    if (-not $name) {
        throw "Component with an empty name detected."
    }

    if (-not $layer) {
        throw "Component '$name' has no layer."
    }

    $layerMap[$name] = $layer
}

$canonicalRows = foreach ($row in $snapshot) {

    $source = ([string]$row.source_component).Trim()
    $target = ([string]$row.target_component).Trim()
    $relation = ([string]$row.relation_type).Trim()
    $description = ([string]$row.description).Trim()

    if (-not $layerMap.ContainsKey($source)) {
        throw "Unknown source component: $source"
    }

    if (-not $layerMap.ContainsKey($target)) {
        throw "Unknown target component: $target"
    }

    $sourceLayer = $layerMap[$source]
    $targetLayer = $layerMap[$target]

    [PSCustomObject]@{
        Layer              = $sourceLayer
        'Source Component' = $source
        'Relation Type'    = $relation
        'Target Component' = $target
        'Layer Flow'       = "$sourceLayer -> $targetLayer"
        Notes              = $description
    }
}

$duplicateGroups = @(
    $canonicalRows |
    Group-Object {
        (
            $_.'Source Component'.ToLowerInvariant() +
            "||" +
            $_.'Relation Type'.ToLowerInvariant() +
            "||" +
            $_.'Target Component'.ToLowerInvariant()
        )
    } |
    Where-Object {
        $_.Count -gt 1
    }
)

if ($duplicateGroups.Count -gt 0) {
    throw "Exact duplicate graph relations detected."
}

$missingMachineLearningRelation = @(
    $canonicalRows |
    Where-Object {
        $_.'Source Component' -eq `
            "Machine Learning and Adaptive Algorithm Module" -and
        $_.'Relation Type' -eq `
            "Supports navigation decision-making of" -and
        $_.'Target Component' -eq `
            "Autonomous Navigation Decision Module"
    }
)

if ($missingMachineLearningRelation.Count -ne 1) {
    throw "Expected ML-to-navigation relation was not found exactly once."
}

$sonarRelation = @(
    $canonicalRows |
    Where-Object {
        $_.'Source Component' -eq "Sonar" -and
        $_.'Target Component' -eq `
            "Data Integration and Analysis Module"
    }
)

if ($sonarRelation.Count -ne 1) {
    throw "Expected exactly one Sonar relation."
}

if (
    $sonarRelation[0].'Relation Type' -ne
    "Provides underwater and environmental sensing input to"
) {
    throw "Sonar relation type was not reconciled correctly."
}

$tempPath = "$relationsPath.tmp"

$canonicalRows |
    Export-Csv `
        -Path $tempPath `
        -NoTypeInformation `
        -Encoding UTF8

Move-Item `
    -Path $tempPath `
    -Destination $relationsPath `
    -Force

$validatedRows = @(Import-Csv $relationsPath)

if ($validatedRows.Count -ne 41) {
    throw "Expected 41 canonical relations after export."
}

$flowSummary = @(
    $validatedRows |
    Group-Object 'Layer Flow' |
    Sort-Object Name |
    ForEach-Object {
        [PSCustomObject]@{
            layer_flow = $_.Name
            relations  = $_.Count
        }
    }
)

Write-Host ""
Write-Host "SYSTEM GRAPH RECONCILIATION PASSED"
Write-Host ""
Write-Host "Previous canonical records: 40"
Write-Host "Reconciled canonical records: $($validatedRows.Count)"
Write-Host "Exact duplicates: 0"
Write-Host ""
Write-Host "Layer-flow distribution:"

$flowSummary |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Added relation:"
Write-Host (
    "Machine Learning and Adaptive Algorithm Module" +
    " -> Autonomous Navigation Decision Module"
)

Write-Host ""
Write-Host "Corrected Sonar relation type:"
Write-Host (
    "Provides underwater and environmental sensing input to"
)

Write-Host ""
Write-Host "Updated:"
Write-Host $relationsPath
Write-Host ""
Write-Host "Backup:"
Write-Host $backupPath
