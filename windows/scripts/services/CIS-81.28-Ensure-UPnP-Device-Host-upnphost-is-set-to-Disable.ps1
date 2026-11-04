# CIS 81.28 (L1) Ensure 'UPnP Device Host (upnphost)' is set to 'Disabled'
# No MDM CSP writes the value this check reads.
# $Mode = 'Check' (default) only reports: exit 0 = compliant, 1 = not. Nothing changes.
# To remediate (e.g. as a Fleet policy automation), upload a copy with $Mode = 'Apply'.
$Mode = 'Check'
$ErrorActionPreference = 'Stop'
function Test-Svc($Name, $Allowed) {
  # Exact match: Get-Service -Name also matches display names (e.g. 'Browser' finds the 'bowser' driver).
  $s = Get-Service -Name $Name -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $Name }  # also finds drivers (RSPNDR, LLTDIO)
  if (-not $s) { return $true }  # not installed counts as compliant
  return $Allowed -contains $s.StartType.ToString()
}
$ok = Test-Svc 'upnphost' @('Disabled')
if ($Mode -eq 'Check') { if ($ok) { 'compliant'; exit 0 } else { 'non-compliant'; exit 1 } }
if (-not $ok) {
  Set-Service -Name 'upnphost' -StartupType Disabled
  Stop-Service -Name 'upnphost' -Force -ErrorAction SilentlyContinue
  'fixed'
} else { 'already compliant' }
