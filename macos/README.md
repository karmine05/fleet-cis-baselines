# macOS 26 Tahoe (CIS benchmark)

119 Fleet policies for the CIS Apple macOS 26 Tahoe Benchmark v1.0.0, with a profile or script to fix each one where possible.

| Path | What |
|---|---|
| `policies.yaml` | 119 policies |
| `catalog.csv` | One row per policy: fix, label, risk, notes |
| `profiles/*.mobileconfig` | 15 configuration profiles, one per area. All pass `plutil -lint` |
| `scripts/CIS-<id>.sh` | 40 shell scripts with `--check` and `--apply` |
| `section-map.csv` | Policy to CIS Controls v8.1 safeguard |

## How to fix each policy

| Remediation | Policies | What to do |
|---|---|---|
| `profile` | 62 | Upload the profile and scope it to `CIS scope - macOS MDM enrolled`. These checks read `managed_policies`, so they only pass when the setting comes from MDM |
| `script` | 40 | Settings in local plists, pmset, sudoers, authorizationdb, launchd or the application firewall |
| `fleet-feature` | 4 | OS updates and FileVault (Fleet **OS updates** and **Disk encryption**, both need MDM). Software inventory is already collected by Fleet |
| `manual` | 11 | SIP, AMFI and SSV (Recovery only), XProtect, Time Machine, Find My, the Safari Hide IP setting, location app review, computer name, Apple-managed world-writable folders |
| `not-applicable` | 2 | Legacy CoreStorage, and Intel laptop standby on Apple silicon |

## Profiles

| Profile | Payload | Covers |
|---|---|---|
| `cis-safari` | com.apple.Safari | Safari security and privacy (6.3.x) |
| `cis-terminal` | com.apple.Terminal | Secure keyboard entry (6.4.1) |
| `cis-passcode` | com.apple.mobiledevice.passwordpolicy | Local password policy (5.2.x) |
| `cis-restrictions-l1` | com.apple.applicationaccess | Level 1 restrictions, including Siri off |
| `cis-restrictions-l2-audit` | com.apple.applicationaccess | Level 2 and audit restrictions (iCloud, Lockdown, Game Center, Apple Pay, accounts). Edit to match your organization before you upload it |
| `cis-softwareupdate` | com.apple.SoftwareUpdate | Automatic updates (1.2 to 1.5) |
| `cis-screensaver` | com.apple.screensaver | Idle time and password on wake (2.11.1, 2.11.2) |
| `cis-loginwindow` | com.apple.loginwindow | Login window, password hints, auto-login (2.11.4, 2.11.5, 2.13.3) |
| `cis-privacy-analytics` | SubmitDiagInfo, Accessibility, assistant.support, Spotlight | Analytics and data sharing (2.6.3.x, 2.9.1) |
| `cis-bonjour` | com.apple.mDNSResponder | Bonjour advertising off (4.1) |
| `cis-controlcenter` | com.apple.controlcenter | Wi-Fi and Bluetooth in the menu bar (2.4.1) |
| `cis-universalcontrol` | com.apple.universalcontrol | Universal Control off (2.8.1) |
| `cis-apple-intelligence` | IntelligencePlatform, mail, notes, writingtools | Apple Intelligence features (2.5.1.x) |
| `cis-appstore` | com.apple.appstore | Admin-only App Store installs (2.1.2) |
| `cis-firewall` | com.apple.security.firewall | Firewall and stealth mode (2.2.1, 2.2.2). An MDM alternative to the two firewall scripts |

Deleting a macOS profile undoes its settings.

## Labels

- `macOS` (built in): default for script and fleet-feature policies.
- `CIS scope - macOS MDM enrolled`: all profile-backed policies.
- `CIS scope - macOS laptops`: sleep and battery items, so always-on Macs are not put to sleep.
- `CIS scope - macOS Intel laptops`: Intel standby items.

If you scope the profile-backed policies to MDM-enrolled Macs, add one policy that checks MDM is on. Otherwise Macs without MDM drop out of the report without anyone noticing.

## Risky settings

| CIS | What breaks |
|---|---|
| 2.10.1.2 sleep | Macs that act as servers go to sleep and their services stop. Scope to laptops |
| 2.13.3, 2.11.4 auto-login off | Apps that start at login on a headless Mac stay down after a reboot until someone signs in |
| 2.3.3.1, 2.3.3.4, 2.3.3.5 | Screen Sharing, SSH and Remote Management are turned off. Headless Macs can become unreachable |
| 2.2.1, 2.2.2 firewall and stealth | Unsigned listeners (local model servers, Docker port forwards) get blocked; ping stops answering |
| 1.2 to 1.5, 1.1 automatic updates | Unattended reboots |
| 2.6.6, 5.3.1 FileVault | A headless Mac waits at the unlock screen after a reboot unless you use `fdesetup authrestart` |
| 4.1 Bonjour advertising off | Other hosts can no longer find the Mac by its `.local` name |
| 5.1.1 home folders 700 | Services that read another user's home folder through group access stop working |

## Known query limits

- **3.2 and 3.4:** they read `/etc/security/audit_control`. Recent macOS ships only `audit_control.example`, because OpenBSM auditd is deprecated. The scripts put the file in place and turn auditd on.
- **2.6.3.1 and 2.6.3.2:** they expect `Siri Data Sharing Opt-In Status` in `com.apple.applicationaccess`. That is not an Apple restrictions key. The L1 restrictions profile adds it so the check can pass.
- **2.10.1.2 and 2.10.2:** the titles say Apple silicon and Intel, but both policies run on every Mac. Use the laptop labels.
- **Unconfirmed keys:** `allowCloudAnalytics`, `allowTouchID` and the Spotlight, IntelligencePlatform, writingtools and notes domains come from the policy queries. They are not confirmed against Apple's documentation. The `notes` column flags each one.

## How this was tested

- **Scripts:** all 40 ran in check mode on a Mac. 38 gave the same result as Fleet; the other 2 have no Fleet data to compare with.
- **Profiles:** 14 of the 15 profiles were deployed through Fleet MDM to an enrolled Mac and applied cleanly. `cis-restrictions-l2-audit` was not deployed because its values are organization-specific.
- **Policies:** in the original set, 16 duplicate or contradictory policies were removed: 7 extra Siri variants, the non-CIS half of four on/off pairs (one half always failed), and checks whose query tested something other than their title.
- **Not tested:** fix mode for the scripts.
