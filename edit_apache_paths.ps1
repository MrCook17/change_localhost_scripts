# Define the base directory containing projects
$base_dir = "C:\Users\Charlie\Documents\Coding\web_development\projects"

# Get all subdirectories (projects)
$projects = Get-ChildItem -Path $base_dir -Directory | Select-Object -ExpandProperty Name

if (-not $projects) {
    Write-Host "No projects found in $base_dir"
    exit
}

# Display a menu to choose a project
Write-Host "Select a project for localhost:"
for ($i = 0; $i -lt $projects.Count; $i++) {
    Write-Host "[$i] $($projects[$i])"
}

# Get user selection
$selection = Read-Host "Enter the number of the project"

if ($selection -match "^\d+$" -and [int]$selection -ge 0 -and [int]$selection -lt $projects.Count) {
    $selected_project = $projects[$selection]
    $new_path = "$base_dir\$selected_project"
} else {
    Write-Host "Invalid selection. Exiting."
    exit
}

# Define config file paths
$httpd_conf = "C:\xampp\apache\conf\httpd.conf"
$httpd_ssl_conf = "C:\xampp\apache\conf\extra\httpd-ssl.conf"

# Regular expressions to match existing paths
$documentRootPattern = 'DocumentRoot\s+"[^"]+"'  # Matches: DocumentRoot "any/path"
$directoryPattern = '<Directory\s+"[^"]+">'      # Matches: <Directory "any/path">

# Modify httpd.conf
(Get-Content $httpd_conf) -replace $documentRootPattern, "DocumentRoot `"$new_path`"" `
                           -replace $directoryPattern, "<Directory `"$new_path`">" `
                           | Set-Content $httpd_conf

# Modify httpd-ssl.conf
(Get-Content $httpd_ssl_conf) -replace $documentRootPattern, "DocumentRoot `"$new_path`"" `
                              | Set-Content $httpd_ssl_conf

Write-Host "Configuration updated to use $new_path for localhost."

# Stop Apache Service
Write-Host "Stopping Apache..."
Start-Process -FilePath "net" -ArgumentList "stop Apache2.4" -Wait -NoNewWindow

# Start Apache Service
Write-Host "Starting Apache..."
Start-Process -FilePath "net" -ArgumentList "start Apache2.4" -NoNewWindow

Write-Host "Apache restarted successfully."

# Wait for manual stop
Write-Host "Press any key to stop Apache when you're done..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Stop Apache manually
Write-Host "Stopping Apache manually..."
Start-Process -FilePath "net" -ArgumentList "stop Apache2.4" -Wait -NoNewWindow

Write-Host "Apache has been stopped."
