# Print at the beginning
Write-Output "Starting the deletion process..."

# Get the current directory path
$currentDir = Get-Location

# Find and delete bin, obj, and node_modules folders, printing each deleted folder's relative path
Get-ChildItem .\ -Include bin,obj,node_modules -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Substring($currentDir.Length)
    Write-Output "Deleting folder: $relativePath"
    Remove-Item $_.FullName -Force -Recurse
}

# Print at the end
Write-Output "Deletion process completed."
