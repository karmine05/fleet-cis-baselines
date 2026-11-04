# CIS 4.4.2 (L1) Ensure 'Configure SMB v1 client driver' is set to 'Enabled: Disable driver (recommended)'
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
$p = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\mrxsmb10'
$ok = Test-Reg $p 'Start' { param($v) "$v" -eq '4' } $false
if ($Mode -eq 'Check') { if ($ok) { 'compliant'; exit 0 } else { 'non-compliant'; exit 1 } }
if (-not $ok) { Set-Reg $p 'Start' DWord 4; 'fixed' } else { 'already compliant' }
