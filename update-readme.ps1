# Script to automatically update README.md Contents section
# This script scans the directory structure and generates a Contents section

param(
    [string]$ReadmePath = "README.md"
)

# Get the repository root
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to generate directory tree
function Get-DirectoryTree {
    param(
        [string]$Path,
        [int]$Depth = 0,
        [int]$MaxDepth = 3
    )
    
    $items = @()
    
    if ($Depth -ge $MaxDepth) {
        return $items
    }
    
    try {
        $children = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".git" -and $_.Name -ne ".github" -and $_.Name -ne "node_modules" }
        
        foreach ($child in $children | Sort-Object -Property @{Expression = {$_.PSIsContainer}; Ascending = $false}, Name) {
            $indent = "  " * $Depth
            $name = $child.Name
            
            if ($child.PSIsContainer) {
                # It's a directory
                $items += "$indent- **$name/**"
                $items += Get-DirectoryTree -Path $child.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
            }
            else {
                # It's a file
                $items += "$indent- $name"
            }
        }
    }
    catch {
        Write-Error "Error processing path $Path : $_"
    }
    
    return $items
}

# Read the current README.md
$readmePath = Join-Path $repoRoot $ReadmePath
if (-not (Test-Path $readmePath)) {
    Write-Error "README.md not found at $readmePath"
    exit 1
}

$readmeContent = Get-Content -Path $readmePath -Raw

# Generate the Contents section
$treeItems = Get-DirectoryTree -Path $repoRoot

$contentsSection = @"
## Contents

``````
"@

foreach ($item in $treeItems) {
    $contentsSection += "$item`n"
}

$contentsSection += @"
``````

This section is auto-generated. Do not edit manually.
"@

# Replace the Contents section using regex
$pattern = "## Contents\s*\n\`\`\`\n[\s\S]*?This section is auto-generated\. Do not edit manually\.\s*\n"
$replacement = "$contentsSection`n"

if ($readmeContent -match $pattern) {
    $updatedContent = $readmeContent -replace $pattern, $replacement
}
else {
    # If pattern doesn't exist, append it before the last line
    $lines = $readmeContent -split "`n"
    $updatedContent = ($lines[0..($lines.Count - 2)] -join "`n") + "`n`n$contentsSection`n`n" + $lines[-1]
}

# Write back to README.md
Set-Content -Path $readmePath -Value $updatedContent -Encoding UTF8

Write-Host "✓ README.md Contents section updated successfully!"
