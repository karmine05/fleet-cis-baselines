# CIS policies for Fleet

[Fleet](https://fleetdm.com) policies for the CIS benchmarks on Windows 11, macOS 26 and Ubuntu 24.04, with the fixes to go with them.

- A **policy** checks one setting on a host and reports pass or fail.
- A **configuration profile** (Windows CSP XML or macOS `.mobileconfig`) sets that setting through MDM.
- A **script** sets it where no profile can.

Use any file on its own. You do not need the whole repo.

| Folder | Policies | Fixes |
|---|---|---|
| [`windows/`](windows/) | 457 (CIS Windows 11 Intune benchmark: L1 337, L2 86, BitLocker 34) | 320 profiles, 98 PowerShell scripts |
| [`macos/`](macos/) | 119 (CIS macOS 26 Tahoe) | 15 profiles, 40 shell scripts |
| [`ubuntu/`](ubuntu/) | 187 (DISA STIG for Ubuntu 24.04) | 158 shell scripts |
| [`labels/`](labels/) | 19 labels that scope the above to the right hosts | `apply_policy_scope.py` |

Each OS folder has the same layout:

```
policies.yaml or policies/   Fleet policies (fleetctl apply format)
catalog.csv                  one row per policy: how to fix it, where to scope it, what can break
profiles/                    MDM configuration profiles
scripts/                     check/fix scripts
section-map.csv              policy to CIS Controls v8.1 safeguard
```

`cis-controls-v8.1.csv` is the CIS Controls v8.1 safeguard list that the `cis_safeguard_ids` tags refer to.

## Quick start

1. **Add the labels.** They decide which hosts run which policy.
   ```sh
   fleetctl apply -f labels/labels.yml
   ```
2. **Add the policies** to a team.
   ```sh
   fleetctl apply --policies-team "Workstations" -f windows/policies/cis-win11-l1.yaml
   fleetctl apply --policies-team "Workstations" -f macos/policies.yaml
   fleetctl apply --policies-team "Servers" -f ubuntu/policies.yaml
   ```
3. **Scope the policies** to their labels. This is a dry run until you add `--apply`.
   ```sh
   export FLEET_URL=https://fleet.example.com FLEET_API_TOKEN=...
   labels/apply_policy_scope.py --team-id 1
   ```
4. **Fix what fails.** Look up the policy in the OS folder's `catalog.csv`. The `profile_file`, `script_file` or `remediation_file` column names the fix.
   - Profiles: upload to the team in **Controls > OS settings > Custom settings**. Scope them with the same labels.
   - Scripts: upload to **Controls > Scripts** in fix mode (see below). Then attach the script to the policy as its automation.

## Scripts

Every script runs in check mode unless you change one line:

| | Check (default) | Fix |
|---|---|---|
| Windows (`.ps1`) | `$Mode = 'Check'` | `$Mode = 'Apply'` |
| macOS, Ubuntu (`.sh`) | `DEFAULT_MODE=--check` | `DEFAULT_MODE=--apply` |

Check mode changes nothing. It exits 0 when the host is compliant and 1 when it is not. Fix mode changes the setting and then checks again. You can also pass `--check` or `--apply` to the shell scripts when you run them by hand.

## Before you deploy

Some CIS settings cut off remote access or stop services. The `risk` column in each `catalog.csv` marks them. The worst ones:

- **Windows:** turning off RDP, WinRM or the Server service; "Deny access from network" set to *Local account*; a TPM startup PIN; DeviceLock password rules; LAPS with an Entra ID backup on a domain without Entra.
- **macOS:** sleep, auto-login off and firewall stealth mode on Macs that act as servers; turning off SSH or Screen Sharing on headless Macs.
- **Ubuntu:** ufw default-deny, sshd crypto and timeout changes, PAM lockout, and removing `NOPASSWD` sudo.

Roll out in this order:

1. Make a manual label with one test host. Scope the profiles and scripts to it.
2. Check that remote access and your services still work, and that the policies pass.
3. Widen the scope to the real labels one OS version at a time.
4. Do not attach fix scripts to hosts that run infrastructure. Use `labels_exclude_any` on the automation.

**Removing a Windows profile does not always undo its setting.** Before you start, take a baseline with [`windows/tools/baseline.ps1`](windows/tools/baseline.ps1), which is read-only. To roll back, push the baseline values as a new profile. Then run `gpupdate /force` for user rights. Removing a macOS profile undoes it.

## How this was tested

Everything here was run on a Fleet 4.94 test environment with these hosts:

- Windows 11 Pro 25H2 and 26H2
- Windows 10 Pro 22H2
- Windows Server 2022 (domain controllers and a member server)
- Ubuntu 24.04 and 26.04
- macOS 27

Each OS README lists what was tested and what was not.

## License

MIT. See [LICENSE](LICENSE).
