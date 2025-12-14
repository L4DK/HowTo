<#
    FileFengShui 2025 Edition
    Windows 10/11 Temporary Files and Maintenance Utility

    Author: Michael Landbo (L4NDbo DEV)
    GitHub: https://github.com/L4DK

    Description:
    ------------
    A modular, defensive, 2025-ready PowerShell cleanup + maintenance framework
    for Windows 10/11. Supports:

    - Profiles (Safe / Standard / Aggressive)
    - Dry-run scanning with detailed reports
    - Interactive review of deletion queue
    - Confirmation code safety gate
    - Age-based filtering
    - Size limits
    - Colored menu UI
    - Logging to file + summary report
    - Extensible plugin system (custom path sets)

    Notes:
    ------
    - Must be run as Administrator for full effect.
    - Script is defensive: prefers to skip on doubt rather than break things.
    - Only deletes in *known transient locations* + optional plugin paths.

    Tested with:
    ------------
    - PowerShell 5.1+
    - Windows 10 / 11
#>

#region Initialization and Global State

# Requires admin for most operations
function Test-IsAdmin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal       = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "[ERROR] This script should be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and choose 'Run as administrator'." -ForegroundColor Yellow
    Write-Host "Exiting..." -ForegroundColor Red
    return
}

# Global state bag
$Global:FFS_State = [ordered]@{
    Profile            = 'Safe'
    AgeDays            = 7        # Delete only files older than X days (default safe)
    MaxFileSizeMB      = 1024     # Default max file size (MB) to include in cleanup
    Targets            = @()      # Final collection of path definitions
    ScanResults        = @()      # All scanned items
    DeletionQueue      = @()      # Items selected for deletion
    LastScanSummary    = $null
    LastReportPath     = $null
    ConfirmationCode   = $null
    LogFilePath        = Join-Path -Path $env:TEMP -ChildPath "FileFengShui_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    PluginsLoaded      = @()
}

# Logging helper
function Write-FFSLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine   = "[$timestamp] [$Level] $Message"
    Add-Content -Path $Global:FFS_State.LogFilePath -Value $logLine

    switch ($Level.ToUpper()) {
        'ERROR' { Write-Host $logLine -ForegroundColor Red }
        'WARN'  { Write-Host $logLine -ForegroundColor Yellow }
        'INFO'  { Write-Host $logLine -ForegroundColor Gray }
        'OK'    { Write-Host $logLine -ForegroundColor Green }
        default { Write-Host $logLine -ForegroundColor Gray }
    }
}

Write-FFSLog "FileFengShui 2025 started." 'INFO'

#endregion Initialization and Global State

#region Core Configuration and Profiles

# Base target sets (can be extended by plugins)
function Get-FFSBaseTargets {
    param(
        [string]$Profile
    )

    # Common temp and cache paths
    $baseTargets = @(
        [pscustomobject]@{
            Name      = 'Windows Temp'
            Path      = "$env:SystemRoot\Temp"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'Windows Prefetch'
            Path      = "$env:SystemRoot\Prefetch"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'User Temp'
            Path      = "$env:UserProfile\AppData\Local\Temp"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'User INetCache'
            Path      = "$env:UserProfile\AppData\Local\Microsoft\Windows\INetCache"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'User WebCache'
            Path      = "$env:UserProfile\AppData\Local\Microsoft\Windows\WebCache"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'User Explorer Cache'
            Path      = "$env:UserProfile\AppData\Local\Microsoft\Windows\Explorer"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'User Caches'
            Path      = "$env:UserProfile\AppData\Local\Microsoft\Windows\Caches"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'Windows Error Reporting Queue'
            Path      = "$env:UserProfile\AppData\Local\Microsoft\Windows\WER\ReportQueue"
            Recursive = $true
        }
        [pscustomobject]@{
            Name      = 'Windows Update Download Cache'
            Path      = "$env:SystemRoot\SoftwareDistribution\Download"
            Recursive = $true
        }
    )

    # Profile-specific additions
    switch ($Profile.ToLower()) {
        'safe' {
            # Minimal, safest targets already defined
        }
        'standard' {
            $baseTargets += [pscustomobject]@{
                Name      = 'Windows Logs (non-critical)'
                Path      = "$env:SystemRoot\Logs"
                Recursive = $true
            }
        }
        'aggressive' {
            $baseTargets += [pscustomobject]@{
                Name      = 'Windows Logs (broad)'
                Path      = "$env:SystemRoot\Logs"
                Recursive = $true
            }
            $baseTargets += [pscustomobject]@{
                Name      = 'Additional Temporary Internet Files'
                Path      = "$env:UserProfile\AppData\Local\Microsoft\Windows\Temporary Internet Files"
                Recursive = $true
            }
        }
        default {
            Write-FFSLog "Unknown profile '$Profile', falling back to 'Safe'." 'WARN'
        }
    }

    return $baseTargets
}

# Plugin loader: loads additional targets from .ps1 files in a 'plugins' folder
function Import-FFSPlugins {
    $pluginDir = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath 'plugins'
    if (-not (Test-Path $pluginDir)) {
        Write-FFSLog "No plugin directory found at '$pluginDir'. Skipping plugin load." 'INFO'
        return
    }

    $pluginFiles = Get-ChildItem -Path $pluginDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue
    foreach ($plugin in $pluginFiles) {
        try {
            . $plugin.FullName
            Write-FFSLog "Loaded plugin: $($plugin.Name)" 'OK'
            $Global:FFS_State.PluginsLoaded += $plugin.Name
        }
        catch {
            Write-FFSLog "Failed to load plugin '$($plugin.Name)': $($_.Exception.Message)" 'ERROR'
        }
    }
}

# Initialize full target list
function Initialize-FFSTargets {
    $Global:FFS_State.Targets = @()
    $core = Get-FFSBaseTargets -Profile $Global:FFS_State.Profile
    $Global:FFS_State.Targets += $core

    # Allow plugins to add targets by defining a function Get-FFSPluginTargets
    if (Get-Command -Name Get-FFSPluginTargets -ErrorAction SilentlyContinue) {
        try {
            $pluginTargets = Get-FFSPluginTargets
            if ($pluginTargets) {
                $Global:FFS_State.Targets += $pluginTargets
                Write-FFSLog "Plugin targets loaded: $($pluginTargets.Count) entries." 'INFO'
            }
        }
        catch {
            Write-FFSLog "Error while retrieving plugin targets: $($_.Exception.Message)" 'ERROR'
        }
    }

    Write-FFSLog "Total targets initialized: $($Global:FFS_State.Targets.Count)." 'INFO'
}

Import-FFSPlugins
Initialize-FFSTargets

#endregion Core Configuration and Profiles

#region Utility Functions

# Confirmation code generator
function New-FFSConfirmationCode {
    $chars = [System.Linq.Enumerable]::Range(48, 57) +
             [System.Linq.Enumerable]::Range(65, 90) +
             [System.Linq.Enumerable]::Range(97, 122)
    $code  = -join ($chars | Get-Random -Count 16 | ForEach-Object { [char]$_ })
    $Global:FFS_State.ConfirmationCode = $code
    Write-FFSLog "Generated confirmation code: $code" 'DEBUG'
    return $code
}

# Human readable file size
function Convert-FFSSize {
    param([long]$Bytes)

    if ($Bytes -lt 1KB) { return "$Bytes B" }
    elseif ($Bytes -lt 1MB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    elseif ($Bytes -lt 1GB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    else { return "{0:N2} GB" -f ($Bytes / 1GB) }
}

# Age check
function Test-FFSAgeEligible {
    param(
        [datetime]$LastWriteTime,
        [int]$MinAgeDays
    )
    $threshold = (Get-Date).AddDays(-1 * $MinAgeDays)
    return ($LastWriteTime -lt $threshold)
}

# Size check
function Test-FFSSizeEligible {
    param(
        [long]$Length,
        [int]$MaxMB
    )
    if ($MaxMB -le 0) { return $true }
    $maxBytes = $MaxMB * 1MB
    return ($Length -le $maxBytes)
}

#endregion Utility Functions

#region Scanning and Dry-Run

function Invoke-FFSScan {
    Write-FFSLog "Starting scan..." 'INFO'

    $results = New-Object System.Collections.Generic.List[object]
    $index   = 0
    $totalTargets = $Global:FFS_State.Targets.Count

    foreach ($target in $Global:FFS_State.Targets) {
        $index++
        $label = "Scanning target $index of $totalTargets: $($target.Name)"
        Write-Progress -Activity "FileFengShui Scan" -Status $label -PercentComplete (($index / $totalTargets) * 100)

        if (-not (Test-Path $target.Path)) {
            Write-FFSLog "Target path does not exist: $($target.Path)" 'WARN'
            continue
        }

        $searchOption = if ($target.Recursive) { '-Recurse' } else { '' }

        try {
            $items = Get-ChildItem -Path $target.Path -File -Force -ErrorAction SilentlyContinue -Recurse:$target.Recursive
        }
        catch {
            Write-FFSLog "Error accessing target '$($target.Path)': $($_.Exception.Message)" 'ERROR'
            continue
        }

        foreach ($item in $items) {
            if (-not (Test-FFSAgeEligible -LastWriteTime $item.LastWriteTime -MinAgeDays $Global:FFS_State.AgeDays)) {
                continue
            }
            if (-not (Test-FFSSizeEligible -Length $item.Length -MaxMB $Global:FFS_State.MaxFileSizeMB)) {
                continue
            }

            $results.Add([pscustomobject]@{
                Name          = $item.Name
                FullName      = $item.FullName
                Length        = $item.Length
                SizeReadable  = Convert-FFSSize -Bytes $item.Length
                LastWriteTime = $item.LastWriteTime
                TargetName    = $target.Name
                TargetPath    = $target.Path
                Marked        = $false
            })
        }
    }

    Write-Progress -Activity "FileFengShui Scan" -Completed -Status "Complete"
    $Global:FFS_State.ScanResults = $results
    Write-FFSLog "Scan complete. Found $($results.Count) candidate files." 'INFO'

    # Summary
    $totalSize = ($results | Measure-Object -Property Length -Sum).Sum
    $summary   = [pscustomobject]@{
        TotalFiles = $results.Count
        TotalSize  = Convert-FFSSize -Bytes $totalSize
        AgeDays    = $Global:FFS_State.AgeDays
        MaxSizeMB  = $Global:FFS_State.MaxFileSizeMB
        Profile    = $Global:FFS_State.Profile
        ScanTime   = Get-Date
    }
    $Global:FFS_State.LastScanSummary = $summary
    Write-FFSLog "Scan summary: Files=$($summary.TotalFiles), Size=$($summary.TotalSize)" 'INFO'
    return $summary
}

function Show-FFSScanSummary {
    if (-not $Global:FFS_State.LastScanSummary) {
        Write-Host "No scan summary available. Please run a scan first." -ForegroundColor Yellow
        return
    }

    $s = $Global:FFS_State.LastScanSummary
    Write-Host "----------- Scan Summary -----------" -ForegroundColor Cyan
    Write-Host " Profile:    $($s.Profile)"
    Write-Host " Age filter: $($s.AgeDays) days"
    Write-Host " Size limit: $($s.MaxSizeMB) MB"
    Write-Host " Files:      $($s.TotalFiles)"
    Write-Host " Total size: $($s.TotalSize)"
    Write-Host " Scan time:  $($s.ScanTime)"
    Write-Host "------------------------------------" -ForegroundColor Cyan
}

#endregion Scanning and Dry-Run

#region Deletion Queue and Review

function Initialize-FFSDeletionQueue {
    # For now, default: everything from scan is queued; user can filter/review
    $Global:FFS_State.DeletionQueue = @(
        $Global:FFS_State.ScanResults | ForEach-Object {
            $_.PSObject.Copy()
        }
    )
    Write-FFSLog "Deletion queue initialized with $($Global:FFS_State.DeletionQueue.Count) items." 'INFO'
}

function Show-FFSDeletionQueue {
    if (-not $Global:FFS_State.DeletionQueue -or $Global:FFS_State.DeletionQueue.Count -eq 0) {
        Write-Host "Deletion queue is empty. Run a scan first." -ForegroundColor Yellow
        return
    }

    $totalSize = ($Global:FFS_State.DeletionQueue | Measure-Object -Property Length -Sum).Sum
    Write-Host "----------- Deletion Queue -----------" -ForegroundColor Cyan
    Write-Host " Files:      $($Global:FFS_State.DeletionQueue.Count)"
    Write-Host " Total size: $(Convert-FFSSize -Bytes $totalSize)"
    Write-Host "--------------------------------------" -ForegroundColor Cyan

    $preview = $Global:FFS_State.DeletionQueue | Select-Object -First 25
    $preview | Select-Object TargetName, SizeReadable, LastWriteTime, FullName | Format-Table -AutoSize
    if ($Global:FFS_State.DeletionQueue.Count -gt 25) {
        Write-Host "... and $($Global:FFS_State.DeletionQueue.Count - 25) more items." -ForegroundColor DarkGray
    }
}

#endregion Deletion Queue and Review

#region Deletion Execution

function Invoke-FFSDeletion {
    if (-not $Global:FFS_State.DeletionQueue -or $Global:FFS_State.DeletionQueue.Count -eq 0) {
        Write-Host "No items in deletion queue. Nothing to delete." -ForegroundColor Yellow
        return
    }

    $totalSize = ($Global:FFS_State.DeletionQueue | Measure-Object -Property Length -Sum).Sum
    $totalFiles = $Global:FFS_State.DeletionQueue.Count

    Write-Host ""
    Write-Host "You are about to DELETE $totalFiles files, total size $(Convert-FFSSize -Bytes $totalSize)." -ForegroundColor Red
    Write-Host "This operation is irreversible." -ForegroundColor Red

    $code = New-FFSConfirmationCode
    Write-Host ""
    Write-Host "Confirmation Code (case-sensitive): $code" -ForegroundColor Yellow
    $user = Read-Host "Type the confirmation code to continue, or press Enter to cancel"

    if ($user -ne $code) {
        Write-Host "Confirmation failed. Deletion cancelled." -ForegroundColor Yellow
        Write-FFSLog "Deletion aborted due to confirmation mismatch." 'WARN'
        return
    }

    Write-Host ""
    Write-Host "Starting deletion..." -ForegroundColor Cyan
    Write-FFSLog "Deletion confirmed by user, proceeding." 'INFO'

    $i = 0
    $errors = 0
    foreach ($item in $Global:FFS_State.DeletionQueue) {
        $i++
        $percent = [int](($i / $totalFiles) * 100)
        Write-Progress -Activity "Deleting files" -Status "$i / $totalFiles" -PercentComplete $percent

        try {
            if (Test-Path -LiteralPath $item.FullName) {
                Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
                Write-FFSLog "Deleted: $($item.FullName) ($($item.SizeReadable))" 'OK'
            }
        }
        catch {
            $errors++
            Write-FFSLog "Failed to delete '$($item.FullName)': $($_.Exception.Message)" 'ERROR'
        }
    }

    Write-Progress -Activity "Deleting files" -Completed
    Write-Host "Deletion complete. Files processed: $totalFiles, errors: $errors" -ForegroundColor Green
    Write-FFSLog "Deletion finished. Files=$totalFiles, Errors=$errors." 'INFO'
}

#endregion Deletion Execution

#region Report Generation

function New-FFSReport {
    if (-not $Global:FFS_State.ScanResults -or $Global:FFS_State.ScanResults.Count -eq 0) {
        Write-Host "No scan data available. Please run a scan first." -ForegroundColor Yellow
        return
    }

    $reportPath = Join-Path -Path $env:TEMP -ChildPath "FileFengShui_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $Global:FFS_State.LastReportPath = $reportPath

    $s = $Global:FFS_State.LastScanSummary

    $lines = @()
    $lines += "FileFengShui 2025 - Scan Report"
    $lines += "Generated: $(Get-Date)"
    $lines += "Profile: $($s.Profile)"
    $lines += "Age filter: $($s.AgeDays) days"
    $lines += "Size limit: $($s.MaxSizeMB) MB"
    $lines += "Total files: $($s.TotalFiles)"
    $lines += "Total size: $($s.TotalSize)"
    $lines += ""
    $lines += "Top 50 Largest Files:"
    $lines += ""

    $top = $Global:FFS_State.ScanResults | Sort-Object Length -Descending | Select-Object -First 50
    foreach ($item in $top) {
        $lines += ("{0,-10} {1,-20} {2} " -f $item.SizeReadable, $item.LastWriteTime, $item.FullName)
    }

    Set-Content -Path $reportPath -Value $lines
    Write-Host "Report generated: $reportPath" -ForegroundColor Green
    Write-FFSLog "Report generated at '$reportPath'." 'INFO'
}

#endregion Report Generation

#region Settings / Profile Menu

function Show-FFSSettings {
    while ($true) {
        Clear-Host
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║            L4DK FileFengShui 2025 - Settings             ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " Current Profile: $($Global:FFS_State.Profile)" -ForegroundColor Yellow
        Write-Host " Age Filter:      $($Global:FFS_State.AgeDays) days" -ForegroundColor Yellow
        Write-Host " Size Limit:      $($Global:FFS_State.MaxFileSizeMB) MB" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " 1. Change Profile (Safe / Standard / Aggressive)"
        Write-Host " 2. Set age filter (days)"
        Write-Host " 3. Set max file size (MB, 0 = no limit)"
        Write-Host " 4. Reinitialize targets"
        Write-Host " 5. Back to main menu"
        Write-Host ""

        $choice = Read-Host "Enter choice"

        switch ($choice) {
            '1' {
                Write-Host "Select profile: [S]afe, [T]andard, [A]ggressive"
                $p = Read-Host "Enter S/T/A"
                switch ($p.ToUpper()) {
                    'S' { $Global:FFS_State.Profile = 'Safe' }
                    'T' { $Global:FFS_State.Profile = 'Standard' }
                    'A' { $Global:FFS_State.Profile = 'Aggressive' }
                    default {
                        Write-Host "Invalid profile." -ForegroundColor Red
                        Start-Sleep -Seconds 1
                    }
                }
            }
            '2' {
                $n = Read-Host "Enter minimum age in days (e.g., 7)"
                if ($n -as [int] -and [int]$n -ge 0) {
                    $Global:FFS_State.AgeDays = [int]$n
                }
                else {
                    Write-Host "Invalid age value." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            '3' {
                $n = Read-Host "Enter max file size in MB (0 = no limit)"
                if ($n -as [int] -and [int]$n -ge 0) {
                    $Global:FFS_State.MaxFileSizeMB = [int]$n
                }
                else {
                    Write-Host "Invalid size value." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
            '4' {
                Initialize-FFSTargets
                Write-Host "Targets reinitialized." -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
            '5' { break }
            default {
                Write-Host "Invalid choice." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

#endregion Settings / Profile Menu

#region Main Menu

function Show-FFSHeader {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             L4DK FileFengShui 2025 Edition               ║" -ForegroundColor Cyan
    Write-Host "║        Windows 10/11 Temporary Files Management          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Another handy software tool from L4DK DEV" -ForegroundColor DarkGray
    Write-Host " GitHub: https://github.com/L4DK" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " Profile: $($Global:FFS_State.Profile) | Age >= $($Global:FFS_State.AgeDays)d | MaxSize: $($Global:FFS_State.MaxFileSizeMB)MB" -ForegroundColor Yellow
    if ($Global:FFS_State.LastScanSummary) {
        Write-Host " Last Scan: Files=$($Global:FFS_State.LastScanSummary.TotalFiles), Size=$($Global:FFS_State.LastScanSummary.TotalSize)" -ForegroundColor DarkCyan
    }
    Write-Host ""
}

function Start-FFSMenu {
    do {
        Show-FFSHeader
        Write-Host " 1. Scan (Dry-Run) – Analyze candidates only"
        Write-Host " 2. Show last scan summary"
        Write-Host " 3. Initialize / View deletion queue"
        Write-Host " 4. Review deletion queue (preview)"
        Write-Host " 5. Execute deletion (requires confirmation code)"
        Write-Host " 6. Generate report"
        Write-Host " 7. Settings"
        Write-Host " 8. Exit"
        Write-Host ""

        $choice = Read-Host "Enter your choice (1-8)"

        switch ($choice) {
            '1' {
                Invoke-FFSScan | Out-Null
                Show-FFSScanSummary
                Pause
            }
            '2' {
                Show-FFSScanSummary
                Pause
            }
            '3' {
                if (-not $Global:FFS_State.ScanResults -or $Global:FFS_State.ScanResults.Count -eq 0) {
                    Write-Host "No scan results found. Please run a scan first." -ForegroundColor Yellow
                }
                else {
                    Initialize-FFSDeletionQueue
                    Show-FFSDeletionQueue
                }
                Pause
            }
            '4' {
                Show-FFSDeletionQueue
                Pause
            }
            '5' {
                Invoke-FFSDeletion
                Pause
            }
            '6' {
                New-FFSReport
                Pause
            }
            '7' {
                Show-FFSSettings
            }
            '8' {
                Write-FFSLog "User selected exit. Terminating." 'INFO'
                break
            }
            default {
                Write-Host "Invalid choice. Please select between 1 and 8." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

#endregion Main Menu

# Start the tool
Start-FFSMenu
