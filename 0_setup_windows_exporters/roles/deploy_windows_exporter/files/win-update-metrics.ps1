$outFolder = Join-Path $PSScriptRoot "textfile_inputs"
$outputFile = Join-Path $outFolder "win_updates.prom"

# Ensure the folder exists
if (-not (Test-Path $outFolder)) {
    New-Item -ItemType Directory -Path $outFolder | Out-Null
}

$metricText = @"
# HELP win_upgrades_pending Number of pending Windows updates
# TYPE win_upgrades_pending gauge
"@
$metricText | Out-File -encoding utf8 -FilePath $outputFile

# Pending Updates
$inputString = Get-WindowsUpdate
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"all`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

# Pending Security Updates
$inputString = Get-WindowsUpdate -Category 'SecurityUpdates'
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"security`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

# Pending Critical Updates
$inputString = Get-WindowsUpdate -Category 'CriticalUpdates'
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"critical`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

# Pending Rollup Updates
$inputString = Get-WindowsUpdate -Category 'Update Rollups'
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"rollup`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

# Pending Driver Updates
$inputString = Get-WindowsUpdate -Category 'Drivers'
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"driver`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

# Pending Driver Updates
$inputString = Get-WindowsUpdate -Category 'Updates'
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"update`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

# Pending Antivirus Updates
$inputString = Get-WindowsUpdate -Category 'Definition Updates'
$lineCount = ($inputString -split "`n").Count
"win_upgrades_pending{category=`"antivirus`"} " + $lineCount | Out-File -encoding utf8 -FilePath $outputFile -Append

$metricText = @"
# HELP win_update_reboot_required Check if machine needs reboot from updates
# TYPE win_update_reboot_required gauge
"@
$metricText | Out-File -Encoding utf8 -FilePath $outputFile -Append

# Updates Require Reboot
$rebootStatus = [int](Get-WURebootStatus).RebootRequired
"win_update_reboot_required " + $rebootStatus | Out-File -encoding utf8 -FilePath $outputFile -Append
