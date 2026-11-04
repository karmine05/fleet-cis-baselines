# Labels

Fleet runs a policy on every host of its platform unless you scope it. Scope each policy to the hosts where it can run and where it can be fixed. Otherwise it shows up as "no data", or as a failure nobody can fix.

- Policies take `labels_include_any` or `labels_exclude_any`.
- Configuration profiles also take `labels_include_all`. Use it to combine labels, for example *MDM enrolled* and *Windows 11 workstations*.

## Files

| File | What |
|---|---|
| `labels.yml` | 19 dynamic labels (`fleetctl apply` format) |
| `apply_policy_scope.py` | Sets `labels_include_any` on every policy to the `scope_label` in the catalogs. Matches policies by name |

```sh
fleetctl apply -f labels/labels.yml

export FLEET_URL=https://fleet.example.com
export FLEET_API_TOKEN=...              # or FLEET_TOKEN_FILE=~/fleet.token
export FLEET_CA_FILE=~/fleet-ca.pem     # only for a self-signed server
labels/apply_policy_scope.py --team-id 1           # dry run
labels/apply_policy_scope.py --team-id 1 --apply
```

Scoping changes your compliance numbers. Hosts outside a policy's label stop reporting it, so checks that cannot run no longer drag the pass rate down. Write down the before and after numbers.

## The labels

| Label | Matches | Used for |
|---|---|---|
| CIS scope - Windows workstations | Any Windows client OS | Registry and service checks (175) |
| CIS scope - Windows 11 workstations | Client OS, build 22000 or later | Windows 11-only profiles |
| CIS scope - Windows 10 workstations | Client OS, build below 22000 | Windows 10 rollout |
| CIS scope - Windows Server (all) | Any Server SKU | Keeping workstation items off servers |
| CIS scope - Windows member servers | Server without the `NTDS` service | Server baselines |
| CIS scope - Windows MDM enrolled (Fleet) | Enrollment with ProviderID `Fleet` | All `mdm_bridge` checks (243) and every profile |
| CIS scope - Windows domain-joined | Tcpip `Domain` value set | Spotting GPO and MDM overlap |
| CIS scope - Windows Enterprise or Education | Edition name | Settings Pro rejects (7) |
| CIS scope - Windows TPM ready | `tpm_info` enabled and activated | BitLocker checks (32) |
| CIS scope - macOS MDM enrolled | `mdm.enrolled = true` | Profile-backed macOS checks |
| CIS scope - macOS laptops | MacBook models | Sleep and battery items |
| CIS scope - macOS Intel laptops | Intel MacBook models | Intel standby items |
| CIS scope - Ubuntu 24.04 / 26.04 | `os_version` | Version differences |
| CIS scope - Linux desktops | gdm3 or ubuntu-desktop installed | GNOME items |
| CIS scope - Linux auditd installed | auditd installed | Audit-rule checks (optional) |
| CIS scope - Linux aide installed | aide installed | AIDE check |
| CIS scope - Linux directory joined | sssd installed and configured | SSSD items |
| CIS scope - Linux smart card required | pam_pkcs11 or opensc installed | PIV items |

Caveats:

- **`TPM ready` is necessary, not sufficient.** Some virtual TPMs report enabled and activated, but BitLocker still cannot use them (for example VMs with SeaBIOS).
- **Check the built-in and older labels.** A label like `name LIKE 'Windows%' AND name LIKE '%Server%'` matches nothing, because Windows reports `Microsoft Windows Server ...`. `name LIKE 'Mac OS X%'` matches no modern Mac, which reports `macOS`. And `os_version.name` on Ubuntu Server is just "Ubuntu", so a "Linux Servers" label that looks for "Server" in the name matches nothing.
- **Label queries cannot be edited in Fleet.** To change one, delete the label and create it again.
