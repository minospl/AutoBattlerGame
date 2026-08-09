param(
    [Parameter(Mandatory=$true)][string]$SourceFile,
    [Parameter(Mandatory=$true)][int]$StartLine,
    [Parameter(Mandatory=$true)][int]$EndLine,
    [Parameter(Mandatory=$true)][string]$DestFile,
    [Parameter(Mandatory=$false)][int]$InsertAtLine = -1,
    [Parameter(Mandatory=$false)][int]$ReplaceStartLine = -1,
    [Parameter(Mandatory=$false)][int]$ReplaceEndLine = -1
)

if (-not (Test-Path $SourceFile)) {
    Write-Error "Source file not found: $SourceFile"
    exit 1
}

$sourceLines = Get-Content $SourceFile -Encoding UTF8
if ($StartLine -lt 1 -or $EndLine -gt $sourceLines.Count -or $StartLine -gt $EndLine) {
    Write-Error "Invalid StartLine or EndLine."
    exit 1
}

# Arrays are 0-indexed, lines are 1-indexed
$block = $sourceLines[($StartLine-1)..($EndLine-1)]

$destLines = @()
if (Test-Path $DestFile) {
    $destLines = @(Get-Content $DestFile -Encoding UTF8)
} else {
    $parent = Split-Path $DestFile
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
}

if ($ReplaceStartLine -gt 0 -and $ReplaceEndLine -gt 0) {
    if ($ReplaceStartLine -gt $ReplaceEndLine -or $ReplaceEndLine -gt $destLines.Count) {
        Write-Error "Invalid ReplaceStartLine or ReplaceEndLine."
        exit 1
    }
    $newLines = @()
    if ($ReplaceStartLine -gt 1) {
        $newLines += $destLines[0..($ReplaceStartLine-2)]
    }
    $newLines += $block
    if ($ReplaceEndLine -lt $destLines.Count) {
        $newLines += $destLines[$ReplaceEndLine..($destLines.Count-1)]
    }
    $newLines | Set-Content $DestFile -Encoding UTF8
    Write-Host "Replaced lines $ReplaceStartLine to $ReplaceEndLine in $DestFile with lines $StartLine to $EndLine from $SourceFile."
} elseif ($InsertAtLine -gt 0) {
    if ($InsertAtLine -gt ($destLines.Count + 1)) {
        Write-Error "InsertAtLine is beyond the end of the file."
        exit 1
    }
    $newLines = @()
    if ($InsertAtLine -eq 1) {
        $newLines += $block
        $newLines += $destLines
    } else {
        $newLines += $destLines[0..($InsertAtLine-2)]
        $newLines += $block
        if ($InsertAtLine -le $destLines.Count) {
            $newLines += $destLines[($InsertAtLine-1)..($destLines.Count-1)]
        }
    }
    $newLines | Set-Content $DestFile -Encoding UTF8
    Write-Host "Inserted lines $StartLine to $EndLine from $SourceFile into $DestFile at line $InsertAtLine."
} else {
    # Append
    $newLines = $destLines + $block
    $newLines | Set-Content $DestFile -Encoding UTF8
    Write-Host "Appended lines $StartLine to $EndLine from $SourceFile to $DestFile."
}
