$outFolder = Join-Path $PSScriptRoot "textfile_inputs"
$outputFile = Join-Path $outFolder "win_defender.prom"

# Ensure the folder exists
if (-not (Test-Path $outFolder)) {
    New-Item -ItemType Directory -Path $outFolder | Out-Null
}

$status = Get-MpComputerStatus
$avConfig = Get-MpPreference
$features = @{
    "antispyware" = $status.AntiSpywareEnabled
    "antivirus" = $status.AntivirusEnabled
    "realtime_protection" = $status.RealTimeProtectionEnabled
    "on_access_protection" = $status.OnAccessProtectionEnabled
    "tamper_protection" = $status.IsTamperProtected
    "ioav_protection" = $status.IoavProtectionEnabled
    "nis_enabled" = $status.NISEnabled
    "behavior_monitor" = $status.BehaviorMonitorEnabled
    "am_service" = $status.AMServiceEnabled
    "pua_protection" = $avConfig.PUAProtection
}

@"
# HELP win_defender_enabled Whether Microsoft Defender is enabled
# TYPE win_defender_enabled gauge
"@ | Out-File -encoding utf8 -FilePath $outputFile
foreach ($f in $features.Keys) {
    $v = [int]$features[$f]
    "win_defender_enabled{feature=""$f""} $v" | Out-File -Encoding utf8 -FilePath $outputFile -Append
}

@"
# HELP win_defender_signatures_outdated Whether Defender signatures are outdated
# TYPE win_defender_signatures_outdated gauge
"@ | Out-File -Encoding utf8 -FilePath $outputFile -Append
$outdated = [int]$status.DefenderSignaturesOutOfDate
"win_defender_signatures_outdated $outdated" | Out-File -Encoding utf8 -FilePath $outputFile -Append


@"
# HELP win_defender_am_running_mode Defender antivirus running mode
# TYPE win_defender_am_running_mode gauge
"@ | Out-File -Encoding utf8 -FilePath $outputFile -Append
$mode = switch -Regex ($status.AMRunningMode.ToLowerInvariant()) {
    "passive"         { 3 }  # Passive mode
    "edr"             { 2 }  # used when other AV registers with Windows Security Center (useful when running alongside CrowdStrike)
    "not.*running"    { 0 }  # defender not running, but could be due to another antivirus running
    "normal"          { 1 }  # defender is running (it's still possible to have other AV running)
    default           { -1 }  # Unknown
}
"win_defender_am_running_mode $mode" | Out-File -Encoding utf8 -FilePath $outputFile -Append

@"
# HELP win_defender_signature_last_updated_time Timestamp of last signature update in Unix time
# TYPE win_defender_signature_last_updated_time gauge
"@ | Out-File -Encoding utf8 -FilePath $outputFile -Append

$timestamp = ([datetimeoffset]$status.AntivirusSignatureLastUpdated).ToUnixTimeSeconds()
"win_defender_signature_last_updated_time $timestamp" | Out-File -Encoding utf8 -FilePath $outputFile -Append



##############################################################################
#  Found Virus Threats
#
$severityMap = @{
    0 = "unknown"
    1 = "low"
    2 = "moderate"
    3 = "high"
    4 = "severe"
    5 = "extreme"
}

$typeMap = @{
    0 = "known_bad"
    1 = "behavior"
    2 = "unknown"
    3 = "known_good"
    4 = "nri"
}

# https://learn.microsoft.com/en-us/previous-versions/windows/desktop/defender/msft-mpthreat#members
$categoryMap = @{
    0 = "invalid"
    1 = "adware"
    2 = "spyware"
    3 = "password_stealer"
    4 = "trojan_downloader"
    5 = "worm"
    6 = "backdoor"
    7 = "remote_access_trojan"
    8 = "trojan"
    9 = "email_flooder"
    10 = "key_logger"
    11 = "dialer"
    12 = "monitoring_software"
    13 = "browser_modifier"
    14 = "cookie"
    15 = "browser_plugin"
    16 = "aol_exploit"
    17 = "nuker"
    18 = "security_disabler"
    19 = "joke_program"
    20 = "hostile_activex_control"
    21 = "software_bundler"
    22 = "stealth_notifier"
    23 = "settings_modifier"
    24 = "toolbar"
    25 = "remote_control_software"
    26 = "trojan_ftp"
    27 = "potential_unwanted_software"
    28 = "icq_exploit"
    29 = "trojan_telnet"
    30 = "file_sharing_program"
    31 = "malware_creation_tool"
    32 = "remote_control_software"
    33 = "tool"
    34 = "trojan_denialofservice"
    36 = "trojan_dropper"
    37 = "trojan_massmailer"
    38 = "trojan_monitoringsoftware"
    39 = "trojan_proxyserver"
    40 = "virus"
    42 = "known"
    43 = "unknown"
    44 = "spp"
    45 = "behavior"
    46 = "vulnerability"
    47 = "policy"

    # these are discovered from my own testing
    50 = "ransom"
}


$threats = Get-MpThreat

$totalThreatsCount = @{}

@"
# HELP win_defender_threat_detected Total threats detected by Windows Defender
# TYPE win_defender_threat_detected gauge
"@ | Out-File -Encoding utf8 -FilePath $outputFile -Append

foreach ($threat in $threats) {
    $name = $threat.ThreatName -replace '"', '\"'
    $id = $threat.ThreatID
    $executed = $threat.DidThreatExecute.ToString().ToLower()
    $active = $threat.IsActive.ToString().ToLower()

    $severity = if ($severityMap.ContainsKey([int]$threat.SeverityID)) { $severityMap[[int]$threat.SeverityID] } else { "unknown_$($threat.SeverityID)" }
    $type = if ($typeMap.ContainsKey([int]$threat.TypeID)) { $typeMap[[int]$threat.TypeID] } else { "unknown_$($threat.TypeID)" }
    $category = if ($categoryMap.ContainsKey([int]$threat.CategoryID)) { $categoryMap[[int]$threat.CategoryID] } else { "unknown_$($threat.CategoryID)" }

    "win_defender_threat_detected{name=""$name"", id=""$id"", executed=""$executed"", active=""$active"", severity=""$severity"", type=""$type"", category=""$category""} 1" | Out-File -Encoding utf8 -FilePath $outputFile -Append

    $severityCounts[$severity] = ($severityCounts[$severity] + 1)
    $categoryCounts[$category] = ($categoryCounts[$category] + 1)

    $key = "$severity|$category"
    $totalThreatsCount[$key] = ($totalThreatsCount[$key] + 1)
}

@"
# HELP win_defender_threat_total All threats detected by Windows Defender
# TYPE win_defender_threat_total counter
"@ | Out-File -Encoding utf8 -FilePath $outputFile -Append

foreach ($key in $totalThreatsCount.Keys) {
    $parts = $key -split '\|'
    $severity = $parts[0]
    $category = $parts[1]
    "win_defender_threat_total{severity=""$severity"", category=""$category""} $($totalThreatsCount[$key])" |
        Out-File -Encoding utf8 -FilePath $outputFile -Append
}
