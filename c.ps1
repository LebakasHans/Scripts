$shortcutsFile = "$env:USERPROFILE\cd_shortcuts.json"

function Add-Shortcut {
    param (
        [string]$Name,
        [string]$Path
    )
    # List of reserved command names
    $reservedNames = @("add", "list", "prune", "delete")
    
    # Check if the name is a reserved command
    if ($reservedNames -contains $Name.ToLower()) {
        Write-Host "Error: '$Name' is a reserved command name and cannot be used as a shortcut name."
        return
    }
    
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
        [string]$Name,
        [bool]$OpenInExplorer
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
        
        if ($OpenInExplorer) {
            # Open the path in File Explorer
            Start-Process "explorer.exe" -ArgumentList $shortcuts[$Name]
            Write-Host "Opening '$($shortcuts[$Name])' in File Explorer"
        } else {
            # Change to the directory
            Set-Location $shortcuts[$Name]
        }
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
    # Get all arguments
    $allArgs = $args
    
    # Initialize variables
    $openInExplorer = $false
    $processedArgs = @()
    
    # Process arguments to check for -o flag
    foreach ($arg in $allArgs) {
        if ($arg -eq "-o") {
            $openInExplorer = $true
        } else {
            $processedArgs += $arg
        }
    }
    
    # Extract commands and arguments
    $command = if ($processedArgs.Count -gt 0) { $processedArgs[0] } else { "" }
    $arg1 = if ($processedArgs.Count -gt 1) { $processedArgs[1] } else { "" }
    $arg2 = if ($processedArgs.Count -gt 2) { $processedArgs[2] } else { "" }
    
    # Known commands
    $knownCommands = @("add", "list", "prune", "delete")
    
    # Check if -o is used with a known command (which is incorrect)
    if ($knownCommands -contains $command -and $openInExplorer) {
        Write-Host "Error: The -o flag is only valid when navigating to a shortcut, not with the '$command' command."
        return
    }
    
    # Process based on command
    switch ($command) {
        "add" { 
            Add-Shortcut -Name $arg1 -Path $arg2 
        }
        "list" { 
            List-Shortcuts 
        }
        "prune" { 
            Prune-Shortcuts 
        }
        "delete" {
            if ($arg1 -eq "--all") {
                Delete-AllShortcuts
            } elseif ($arg1) {
                Delete-Shortcut -Name $arg1
            } else {
                Write-Host "Usage: c delete [shortcut_name] or c delete --all"
            }
        }
        default { 
            # If no known command is specified, treat the first argument as a shortcut name
            Go-ToShortcut -Name $command -OpenInExplorer $openInExplorer
        }
    }
}

# Execute when script is called with arguments
if ($MyInvocation.InvocationName -ne '.') {
    # Pass all arguments to the c function
    c @args
}