# Windows 11 (CIS Intune benchmark)

457 Fleet policies for the CIS Microsoft Intune for Windows 11 benchmark, with a profile or script to fix each one where possible.

| Path | What |
|---|---|
| `policies/cis-win11-l1.yaml` | 337 Level 1 policies |
| `policies/cis-win11-l2.yaml` | 86 Level 2 policies |
| `policies/cis-win11-bitlocker.yaml` | 34 BitLocker policies |
| `catalog.csv` | One row per policy: CSP path and value, profile or script, label, risk, notes |
| `profiles/<CSP area>/*.xml` | 320 Fleet-ready profiles (SyncML), one per CSP setting. Checks that share a setting share a profile, for example the 16 ASR rules |
| `profiles/optional/` | Variants that keep common setups working (see below) |
| `scripts/services/`, `scripts/registry/`, `scripts/registry-per-user/` | 98 PowerShell scripts for settings no CSP can write on Windows Pro |
| `tools/baseline.ps1` | Read-only snapshot of services, user rights and MDM policy values. Run it before a rollout so you can roll back |
| `section-map.csv` | Policy to CIS Controls v8.1 safeguard |

## How to fix each policy

The `remediation` column in `catalog.csv`:

| Remediation | Policies | What to do |
|---|---|---|
| `csp-profile` | 344 | Upload `profile_file` to the team and scope it with `scope_label`. 7 of them work only on Enterprise and Education; Pro returns 405 |
| `csp-profile (needs value)` | 2 | CIS 26.3 and 26.4 (DeviceLock). Choose your own value first |
| `script` | 94 | Use `script_file`. Either no CSP writes the value the check reads (MSS TCP/IP values, services, per-user keys), or Windows Pro rejected the CSP |
| `unsupported-node` | 8 | The check reads a CSP setting that Windows 11 Pro 25H2 rejects (404 or 500). It cannot pass on that build |
| `blocked` | 8 | BitLocker startup checks read the MDM provider store, and Fleet does not accept custom BitLocker CSP profiles. Use Fleet disk encryption, or rewrite the check to read `HKLM\SOFTWARE\Policies\Microsoft\FVE` |
| `fleet-feature` | 1 | CIS 8.1 Require Device Encryption: turn on Fleet disk encryption |

Some profiles carry values you must change before you upload them:

- `CIS-49.3` and `CIS-49.4` rename the Administrator and Guest accounts to `CHANGE-ME-*`.
- `CIS-49.9` and `CIS-49.10` set the logon banner. The text is generic; replace it with your own.

## Where to deploy

| Hosts | Deploy | Notes |
|---|---|---|
| Windows 11, MDM enrolled | Everything except the risky items below | 246 checks read MDM state (`mdm_bridge`), so the host must be enrolled in Fleet MDM |
| Windows 10 22H2, MDM enrolled | The same set, minus the ones Windows 10 rejects (list below) | Rejected profiles fail on delivery and change nothing |
| Windows Server | Not this benchmark | Servers cannot enroll in Fleet MDM, so the 246 `mdm_bridge` checks return no data. Use the CIS Server benchmark through Group Policy. The `server_query` column has a registry-only version of 70 checks that runs on Server 2022 |
| Domain-joined PCs | Same as their OS row | A domain GPO wins over MDM for the same setting (audit policy, user rights). Remove the setting from the GPO, or leave it to the GPO |

`scope_label` gives the label for each policy. The `labels/apply_policy_scope.py` script sets them all at once.

### Settings Windows 10 Pro 22H2 rejected

These profiles were rejected by Windows 10 22H2 in testing but accepted on Windows 11. Leave them out of a Windows 10 rollout:

- User rights 89.5, 89.6, 89.10, 89.21, 89.22, 89.30, 89.31, 89.32, 89.33, 89.34 (status 500)
- App Installer 4.11.10.1, 4.11.10.2, 4.11.10.3
- Virtualization-based security 24.2, 90.1, 90.2
- Sudo 79.1, News and Interests 94.1, MPR notifications 4.11.50.1
- Dump and diagnostic log limits 80.7, 80.8, RPC over TCP port 4.7.7
- Firewall success logging 38.5, 38.21 (status 404)

## Risky settings

These are CIS values, but they break common setups. Decide on each one before you deploy it:

| CIS | What breaks |
|---|---|
| 81.17, 81.18, 81.19, 4.11.36.4.2.1 (L2) | RDP is turned off |
| 89.13, 89.17 | "Deny access" for *Local account* blocks RDP with network level authentication for local accounts. Use the Guests-only variant in `profiles/optional/` |
| 81.23 (L2) | Server service off: SMB shares stop. On a domain controller, SYSVOL, NETLOGON and Group Policy stop |
| 81.36 (L2), 4.11.55.2.2, 4.11.56.1 | WinRM and PowerShell remoting stop |
| 4.11.36.4.10.2 | Disconnected RDP sessions are logged off after 1 minute. Unsaved work is lost |
| 4.11.36.4.10.1 | Idle RDP sessions disconnect after 15 minutes |
| 4.11.7.2.12 (BL) | TPM startup PIN: every reboot waits for a PIN at the console. Not usable on VMs |
| 26.2, 26.3, 26.4, 26.7 | DeviceLock rules can force password changes. RDP with network level authentication cannot complete a forced change |
| 105.1, 105.5 (LAPS) | `BackupDirectory=1` backs up to Entra ID. With Active Directory only, use 2. LAPS rotates the built-in Administrator password |
| 49.3 | Renames the built-in Administrator. Anything that signs in by that name breaks |
| 4.4.1 | Local admin accounts other than the built-in Administrator get a filtered token over the network. Use domain accounts for WinRM |
| 81.1, 81.2, 81.13, 81.14, 81.31 | Bluetooth, SSH server, printing (also Print to PDF) and Windows Event Collector stop |

## Optional profiles

`profiles/optional/` holds variants tested on real hosts:

| File | Use it when |
|---|---|
| `CIS-89.13-DenyAccessFromNetwork-GuestsOnly.xml`, `CIS-89.17-DenyRemoteDesktopServicesLogOn-GuestsOnly.xml` | You sign in over RDP with local accounts |
| `CIS-89.10-...-WithServiceAccounts.xml`, `CIS-89.21-...`, `CIS-89.30-...` | You run Hyper-V, or need the Window Manager and WDI service accounts that CIS also allows. The strict versions grant Administrators only |
| `Firewall-Allow-RDP-3389.xml` | You use the CIS firewall profiles (inbound block, local rules ignored) and still need RDP |

## Scripts

- Each script starts in `$Mode = 'Check'`. Upload a copy with `$Mode = 'Apply'` and attach it to the policy as its automation.
- A script writes once. Unlike a profile, nothing applies it again until the policy fails and the automation runs again.
- Service scripts match the service name exactly. `Get-Service -Name Browser` also finds the `bowser` driver through its display name.
- Per-user scripts only change user hives that are loaded, so only users who are signed in when the script runs.
- All scripts are ASCII, so Windows PowerShell 5.1 parses them correctly.

## Known query limits

- CIS 38.1, 38.8 and 38.15 read the local firewall store. The Firewall CSP writes the MDM store, so these are scripted.
- CIS 4.7.4 reads `...\Windows NT\Rpc\RpcAuthentication`. The Printers template uses `...\Windows NT\Printers\RPC`. The script matches the query; check which one you need.
- The old `Policy/Config/Bitlocker/*` CSP returns 404. The BitLocker registry checks are scripted.
- CIS 103.x set Windows Update policy. If Fleet manages OS updates for the team, let Fleet own those settings.

## How this was tested

- **Profiles:** all 320 pass an XML, LocURI and format lint and a Fleet dry run. 311 policies were fixed by a profile on a real Windows 11 Pro PC and then passed in Fleet. In the first test, 137 checks went from fail to pass and none went from pass to fail. A later rollout to two Windows 11 PCs and one Windows 10 PC kept RDP, WinRM and domain access working.
- **Scripts:** every script, run in check mode on 5 hosts, gave the same result as Fleet (480 of 480).
- **Server queries:** the 70 `server_query` checks ran on Server 2022. 51 match the MDM check, and 19 are stricter because they require the setting to be configured explicitly.
- **Not tested:** fix mode for every catalog script. The `tested` column shows the evidence for each row.
