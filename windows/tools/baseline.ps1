# Read-only pre-rollout baseline. Changes nothing.
"== services"
foreach ($n in 'sshd','Spooler','bthserv','BTAGService','Wecsvc','WinRM','LanmanServer','TermService','SessionEnv','UmRdpService') {
  $s = Get-Service -Name $n -EA SilentlyContinue | ? { $_.Name -eq $n }
  if ($s) { "$n|$($s.StartType)|$($s.Status)" } else { "$n|absent" } }
"== bluetooth"
Get-PnpDevice -Class Bluetooth -EA SilentlyContinue | ? Present | % { "$($_.Status)|$($_.FriendlyName)" }
"== sshd_conns"
(Get-NetTCPConnection -LocalPort 22 -State Established -EA SilentlyContinue | Measure-Object).Count
"== printers"
Get-Printer -EA SilentlyContinue | % { "$($_.Name)|$($_.PortName)" }
"== wec_subscriptions"
(wecutil es 2>$null) -join ','
"== rdp"
(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
"== rdu_members"
(Get-LocalGroupMember 'Remote Desktop Users' -EA SilentlyContinue | % Name) -join ','
"== userrights"
secedit /export /cfg $env:TEMP\b.inf /areas USER_RIGHTS | Out-Null
Get-Content $env:TEMP\b.inf | ? { $_ -match '^Se' }
Remove-Item $env:TEMP\b.inf
"== policymanager"
$b='HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device'
Get-ChildItem $b | % { $a=$_.PSChildName; $p=Get-ItemProperty $_.PSPath
  $p.PSObject.Properties | ? { $_.Name -notmatch '^PS|_ProviderSet|_WinningProvider|_LastWrite' } | % { "$a/$($_.Name)=$($_.Value)" } }
