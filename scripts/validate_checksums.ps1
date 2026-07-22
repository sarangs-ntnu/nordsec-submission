$ErrorActionPreference = "Stop"

# PSScriptRoot points to repository\scripts.
# Its direct parent is the repository root.
$repo = Split-Path -Parent $PSScriptRoot

$checksumPath = Join-Path $repo "CHECKSUMS.sha256"

if (-not (Test-Path $checksumPath)) {
    throw "CHECKSUMS.sha256 was not found at: $checksumPath"
}

$entries = @(
    Get-Content `
        -Path $checksumPath `
        -Encoding UTF8 |
    Where-Object {
        $_.Trim()
    }
)

if ($entries.Count -eq 0) {
    throw "CHECKSUMS.sha256 is empty."
}

$verified = 0
$failures = @()

foreach ($entry in $entries) {

    if (
        $entry -notmatch
        '^([A-Fa-f0-9]{64})  (.+)$'
    ) {
        $failures += "Invalid checksum line: $entry"
        continue
    }

    $expectedHash = $matches[1].ToUpperInvariant()
    $relativePath = $matches[2]

    $windowsRelativePath = (
        $relativePath -replace '/', '\'
    )

    $filePath = Join-Path `
        $repo `
        $windowsRelativePath

    if (-not (Test-Path $filePath)) {
        $failures += "Missing file: $relativePath"
        continue
    }

    $actualHash = (
        Get-FileHash `
            -Path $filePath `
            -Algorithm SHA256
    ).Hash.ToUpperInvariant()

    if ($actualHash -ne $expectedHash) {
        $failures += "Hash mismatch: $relativePath"
        continue
    }

    $verified++
}

$trackedFiles = @(
    Get-ChildItem `
        -Path $repo `
        -Recurse `
        -File |
    Where-Object {
        $_.FullName -notlike "*\.git\*" -and
        $_.FullName -ne $checksumPath
    } |
    ForEach-Object {
        $_.FullName.Substring(
            $repo.Length + 1
        ).Replace('\', '/')
    } |
    Sort-Object
)

$checksumFiles = @(
    $entries |
    ForEach-Object {
        if (
            $_ -match
            '^([A-Fa-f0-9]{64})  (.+)$'
        ) {
            $matches[2]
        }
    } |
    Sort-Object
)

$missingFromChecksums = @(
    $trackedFiles |
    Where-Object {
        $_ -notin $checksumFiles
    }
)

$unexpectedChecksumEntries = @(
    $checksumFiles |
    Where-Object {
        $_ -notin $trackedFiles
    }
)

foreach ($file in $missingFromChecksums) {
    $failures += "Not listed in CHECKSUMS.sha256: $file"
}

foreach ($file in $unexpectedChecksumEntries) {
    $failures += "Unexpected checksum entry: $file"
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "CHECKSUM VALIDATION FAILED"

    foreach ($failure in $failures) {
        Write-Host $failure
    }

    throw "Checksum validation failed."
}

Write-Host ""
Write-Host "CHECKSUM VALIDATION PASSED"
Write-Host ""
Write-Host "Repository root: $repo"
Write-Host "Verified files: $verified"
Write-Host "Missing checksum entries: 0"
Write-Host "Unexpected checksum entries: 0"
