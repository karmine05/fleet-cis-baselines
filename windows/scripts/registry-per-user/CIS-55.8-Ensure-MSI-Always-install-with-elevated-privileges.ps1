# CIS 55.8 (L1) Ensure 'MSI Always install with elevated privileges (User)' is set to 'Disabled'
# No MDM CSP writes the value this check reads.
# $Mode = 'Check' (default) only reports: exit 0 = compliant, 1 = not. Nothing changes.
# To remediate (e.g. as a Fleet policy automation), upload a copy with $Mode = 'Apply'.
$Mode = 'Check'
$ErrorActionPreference = 'Stop'
function Test-Reg($Path, $Name, $Want, $AbsentOk = $false) {
  $v = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
  if ($null -eq $v) { return [bool]$AbsentOk }
  return [bool](& $Want $v)
}
function Set-Reg($Path, $Name, $Type, $Value) {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  # Keep the existing value type (some MSS values are REG_SZ); new values use the default type.
  try { $Type = (Get-Item $Path).GetValueKind($Name).ToString() } catch { }
  New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}
$hives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' }
$bad = @($hives | Where-Object { -not (Test-Reg "Registry::HKEY_USERS\$($_.PSChildName)\SOFTWARE\Policies\Microsoft\Windows\Installer" 'AlwaysInstallElevated' { param($v) "$v" -ne '1' } $true) })
# 'Must not be set' checks pass with no user signed in; 'must be set' checks need at least one hive.
$need = $false
if ($Mode -eq 'Check') { if ($bad.Count -eq 0 -and (-not $need -or $hives.Count -gt 0)) { 'compliant'; exit 0 } else { "non-compliant hives: $($bad.Count) of $($hives.Count)"; exit 1 } }
foreach ($h in $bad) { Set-Reg "Registry::HKEY_USERS\$($h.PSChildName)\SOFTWARE\Policies\Microsoft\Windows\Installer" 'AlwaysInstallElevated' DWord 0; "set: $($h.PSChildName)" }
