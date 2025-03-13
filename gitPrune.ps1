# Run 'git fetch -p' to prune deleted remote branches
git fetch -p

# Get the list of local branches with tracking info
$branches = git branch -vv

# Find branches with a '[gone]' upstream
$goneBranches = @()
$branches -split "`n" | ForEach-Object {
    if ($_ -match '^\*?\s*(\S+)\s+[0-9a-f]+\s+\[.*: gone\]') {
        $goneBranches += $matches[1]
    }
}

# If no branches are found, exit
if ($goneBranches.Count -eq 0) {
    Write-Host "No branches found with missing upstream."
    exit
}

# Display branches and ask for confirmation
Write-Host "The following branches have no upstream (remote is gone):"
$goneBranches | ForEach-Object { Write-Host "- $_" }

$confirmation = Read-Host "Do you want to delete these branches? (yes/no)"

if ($confirmation -match "^(y|yes)$") {
    # Delete each branch
    $goneBranches | ForEach-Object {
        git branch -D $_
        Write-Host "Deleted branch: $_"
    }
} else {
    Write-Host "No branches were deleted."
    exit
}
