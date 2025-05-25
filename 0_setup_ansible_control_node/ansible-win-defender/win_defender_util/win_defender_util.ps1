#!powershell
#
# WANT_JSON
# POWERSHELL_COMMON

Set-StrictMode -Version 2;

$changed = $false;

#
# Perform scan operation with windows defender
#
function StartDefenderScan($scanType)
{
  $defender = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
  if (-not (Test-Path $defender))
  {
    return "windows defender utility not found"
  }

  $scanTypeNames = @{
    1 = "QuickScanJob"
    2 = "FullScanJob"
  }

  #
  # check if any kind of scan are ongoing. Launching multiple doesnt seem to
  # be forbidden
  #
  $hasActiveQuickScan = (@(Get-ScheduledJob | Where-Object { $_.Name -in @($scanTypeNames[1])})).Count
  if ($hasActiveQuickScan) {
    return "$($scanTypeNames[1]) is ongoing"
  }

  $hasActiveFullScan = (@(Get-ScheduledJob | Where-Object { $_.Name -in @($scanTypeNames[2])})).Count
  if ($hasActiveFullScan) {
    return "$($scanTypeNames[2]) is ongoing"
  }

  $activeScanJobName = $scanTypeNames[$scanType]

  $formatString = @'
powershell -NoProfile -WindowStyle Hidden -Command "& {{
    Import-Module PSScheduledJob;
    Register-ScheduledJob -Name '{0}' -ScriptBlock {{
        & '{2}' -Scan -ScanType {1};
        Unregister-ScheduledJob -Name '{0}' -Force
    }} -Trigger (New-JobTrigger -Once -At ((Get-Date).AddSeconds(10))) -RunNow
}}"
'@

  #
  # run scan operation detached from WinRM parent
  #
  $command = $formatString -f $activeScanJobName, $scanType, $defender
  ([WmiClass]"Win32_Process").Create($command) | Out-Null

  Set-Variable -Name 'changed' -Value $true -Scope 'script'

  return "$activeScanJobName started"
}


#
# Check for defender updates (will return changed even if updates not needed)
#
function UpdateDefenderSignature()
{
  $defender = Join-Path $env:ProgramFiles "Windows Defender\MpCmdRun.exe"
  if (-not (Test-Path $defender))
  {
    return "windows defender utility not found"
  }

  $signatureUpdateJobName = "SignatureUpdateJob"

  $hasActiveUpdate = (@(Get-ScheduledJob | Where-Object { $_.Name -in @( $signatureUpdateJobName)})).Count
  if ($hasActiveUpdate) {
    return "signature update is ongoing"
  }

  $formatString = @'
powershell -NoProfile -WindowStyle Hidden -Command "& {{
    Import-Module PSScheduledJob;
    Register-ScheduledJob -Name '{0}' -ScriptBlock {{
        & '{1}' -SignatureUpdate;
        Unregister-ScheduledJob -Name '{0}' -Force
    }} -Trigger (New-JobTrigger -Once -At ((Get-Date).AddSeconds(10))) -RunNow
}}"
'@

  $command = $formatString -f $signatureUpdateJobName, $defender
  ([WmiClass]"Win32_Process").Create($command) | Out-Null

  Set-Variable -Name 'changed' -Value $true -Scope 'script'

  return "$signatureUpdateJobName started"
}

# Setting and Reading Params from Ansible
$parsed_args = Parse-Args $args -supports_check_mode $true;
$check_mode = Get-AnsibleParam $parsed_args "_ansible_check_mode" -default $false;

$action = Get-AnsibleParam $parsed_args "action" -validateset "update", "quickscan", "fullscan";

$result_status = ""
if ($action -eq "quickscan")
{
  $result_status = StartDefenderScan 1
}

if ($action -eq "fullscan")
{
  $result_status = StartDefenderScan 2
}

if ($action -eq "update")
{
  $result_status = UpdateDefenderSignature
}

$result = @{
  changed=$changed
  status=$result_status
}

Exit-Json $result;