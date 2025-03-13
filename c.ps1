$shortcutsFile = "$env:USERPROFILE\cd_shortcuts.json"

function Add-Shortcut {
    param (
        [string]$Name,
        [string]$Path
    )
    $shortcuts = @{}
    if (Test-Path $shortcutsFile) {
        $shortcuts = Get-Content $shortcutsFile -Raw | ConvertFrom-Json -AsHashtable
    }
    if ($shortcuts.ContainsKey($Name)) {
        Write-Host "Error: Shortcut '$Name' already exists. Use a different name or delete the existing one first."
        return
    }
    $shortcuts[$Name] = $Path
    $shortcuts | ConvertTo-Json -Depth 10 | Set-Content $shortcutsFile
    Write-Host "Shortcut '$Name' added for path '$Path'"
}

function Go-ToShortcut {
    param (
        [string]$Name
    )
    if (-Not (Test-Path $shortcutsFile)) {
        Write-Host "No shortcuts found. Use 'add [key] [path]' to add one."
        return
    }
    $shortcuts = Get-Content $shortcutsFile -Raw | ConvertFrom-Json -AsHashtable
    if ($shortcuts.ContainsKey($Name)) {
        if (-Not (Test-Path $shortcuts[$Name])) {
            $confirm = Read-Host "Path '$($shortcuts[$Name])' does not exist. Delete shortcut? (y/n)"
            if ($confirm -eq "y") {
                $shortcuts.Remove($Name)
                $shortcuts | ConvertTo-Json -Depth 10 | Set-Content $shortcutsFile
                Write-Host "Shortcut '$Name' deleted."
            }
            return
        }
        Set-Location $shortcuts[$Name]
    } else {
        Write-Host "Shortcut '$Name' not found."
    }
}

function Delete-Shortcut {
    param (
        [string]$Name
    )
    if (-Not (Test-Path $shortcutsFile)) {
        Write-Host "No shortcuts found."
        return
    }
    $shortcuts = Get-Content $shortcutsFile -Raw | ConvertFrom-Json -AsHashtable
    if ($shortcuts.ContainsKey($Name)) {
        $deletedPath = $shortcuts[$Name]
        $shortcuts.Remove($Name)
        $shortcuts | ConvertTo-Json -Depth 10 | Set-Content $shortcutsFile
        Write-Host "Shortcut '$Name' deleted. Path was: '$deletedPath'"
    } else {
        Write-Host "Shortcut '$Name' not found."
    }
}

function List-Shortcuts {
    if (-Not (Test-Path $shortcutsFile)) {
        Write-Host "No shortcuts found."
        return
    }
    $shortcuts = Get-Content $shortcutsFile -Raw | ConvertFrom-Json -AsHashtable
    if ($shortcuts.Count -eq 0) {
        Write-Host "No shortcuts available."
        return
    }
    Write-Host "Stored Shortcuts:"
    $shortcuts.GetEnumerator() | ForEach-Object { Write-Host $_.Key "->" $_.Value }
}

function Prune-Shortcuts {
    if (-Not (Test-Path $shortcutsFile)) {
        Write-Host "No shortcuts found."
        return
    }
    $shortcuts = Get-Content $shortcutsFile -Raw | ConvertFrom-Json -AsHashtable
    $removed = 0
    $keysToRemove = @()
    foreach ($key in $shortcuts.Keys) {
        if (-Not (Test-Path $shortcuts[$key])) {
            $keysToRemove += $key
            $removed++
        }
    }
    foreach ($key in $keysToRemove) {
        $shortcuts.Remove($key)
    }
    $shortcuts | ConvertTo-Json -Depth 10 | Set-Content $shortcutsFile
    Write-Host "$removed invalid shortcuts removed."
}

function Delete-AllShortcuts {
    $confirm = Read-Host "Are you sure you want to delete all shortcuts? (y/n)"
    if ($confirm -eq "y") {
        Remove-Item $shortcutsFile -Force
        Write-Host "All shortcuts deleted."
    } else {
        Write-Host "Operation cancelled."
    }
}

# Main shortcut manager function
function c {
    param (
        [string]$Command,
        [string]$Arg1,
        [string]$Arg2
    )
    switch ($Command) {
        "add" { Add-Shortcut -Name $Arg1 -Path $Arg2 }
        "list" { List-Shortcuts }
        "prune" { Prune-Shortcuts }
        "delete" {
            if ($Arg1 -eq "--all") {
                Delete-AllShortcuts
            } elseif ($Arg1) {
                Delete-Shortcut -Name $Arg1
            } else {
                Write-Host "Usage: c delete [shortcut_name] or c delete --all"
            }
        }
        default { Go-ToShortcut -Name $Command }
    }
}

# Execute when script is called
if ($args.Count -gt 0) {
    c @args
}