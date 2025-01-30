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

# Stop Apache Service if running
Write-Host "Stopping Apache..."
Start-Process -FilePath "net" -ArgumentList "stop Apache2.4" -Wait -NoNewWindow

# Start Apache Service
Write-Host "Starting Apache..."
Start-Process -FilePath "net" -ArgumentList "start Apache2.4" -NoNewWindow

Write-Host "Apache restarted successfully."

# Ask for stop option (manual or automatic)
$stop_option = Read-Host "Enter 'm' to stop Apache manually, or 'a' to stop Apache after a set time (e.g., 30 minutes)"

if ($stop_option -eq 'a') {
    # Stop Apache automatically after a set delay (e.g., 30 minutes)
    $delay_minutes = 1  # Set to 1 minute for test purposes, change as needed
    Write-Host "Apache will stop automatically after $delay_minutes minutes..."

    # Calculate the time for the scheduled task (delay in seconds)
    $delay_seconds = $delay_minutes * 60

    # Create the auto-stop PowerShell script content
    $auto_stop_script = "C:\Users\Charlie\Documents\Coding\auto_stop_apache.ps1"
    $auto_stop_content = @"
Start-Sleep -Seconds ($delay_seconds)  # Wait for the specified time
Write-Host 'Stopping Apache automatically...'
Start-Process -FilePath 'net' -ArgumentList 'stop Apache2.4' -Wait -NoNewWindow
Write-Host 'Apache has been stopped.'
"@
    $auto_stop_content | Out-File -FilePath $auto_stop_script

    # Check if the task already exists, and remove it if it does
    $taskName = "AutoStopApache"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task '$taskName'..."
        Unregister-ScheduledTask -TaskName $taskName
    }

    # Create the trigger for the scheduled task
    $triggerTime = (Get-Date).AddSeconds(5)  # Start the task in 5 seconds, adjust as needed
    $trigger = New-ScheduledTaskTrigger -At $triggerTime -Once  # Trigger once at the specified time

    # Define the action (run PowerShell script to stop Apache)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $auto_stop_script"

    # Create the task and register it
    $task = New-ScheduledTask -Action $action -Trigger $trigger
    Register-ScheduledTask -TaskName $taskName -InputObject $task

    Write-Host "Apache will stop automatically after $delay_minutes minutes. Task scheduled to run in the background."
}

else {
    # Manual stop: Wait for key press
    Write-Host "Press any key to stop Apache manually..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    Write-Host "Stopping Apache manually..."
    Start-Process -FilePath "net" -ArgumentList "stop Apache2.4" -Wait -NoNewWindow
    Write-Host "Apache has been stopped."
}
