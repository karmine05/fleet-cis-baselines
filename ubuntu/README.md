# Ubuntu 24.04 (DISA STIG)

187 Fleet policies for the DISA STIG for Ubuntu 24.04 (`UBTU-24-xxxxxx`). In Fleet they are named `CIS 1.n UBTU-24-xxxxxx` and tagged with CIS Controls v8.1 safeguards. Ubuntu has no MDM profiles, so every fix is a script.

| Path | What |
|---|---|
| `policies.yaml` | 187 policies |
| `catalog.csv` | One row per policy: script, label, risk, notes |
| `scripts/UBTU-24-xxxxxx.sh` | 158 POSIX `sh` scripts with `--check` and `--apply`, one per policy that has one |
| `section-map.csv` | Policy to CIS Controls v8.1 safeguard |

## How to fix each policy

| Remediation | Policies | What it means |
|---|---|---|
| `script` | 155 | `remediation_file`. Two policies share the AIDE and auditd install scripts |
| `manual` | 25 | A decision or a secret only you have: PIV/smart cards, SSSD directory, FIPS (Ubuntu Pro), GRUB password, disk encryption, `NOPASSWD` sudo, a remote audit server |
| `not-applicable` | 7 | 5 desktop-only items (GNOME/gdm3), DoD PKI and wireless. The 5 desktop items still have scripts |

Packages that the scripts install with apt can also be deployed as Fleet software.

## Scripts

- `script.sh --check` is read-only. It exits 0 when compliant and 1 when not.
- `script.sh --apply` exits 0 when the host is already compliant. Otherwise it fixes the setting and checks again.
- Fleet runs scripts without arguments, so `DEFAULT_MODE=--check` at the top decides what a Fleet run does. To fix through Fleet, upload a copy with `DEFAULT_MODE=--apply`.
- The checks test what the STIG asks for (for example `sshd -T` effective values). They do not copy the Fleet query.

## Labels

`Ubuntu Linux` (built in) is the default for all 187. These narrow the scope where a policy cannot pass or cannot run:

| Label | Use |
|---|---|
| `CIS scope - Linux desktops` | 5 gdm3/dconf items |
| `CIS scope - Linux auditd installed` | Audit-rule checks, if you only want them counted after auditd is installed |
| `CIS scope - Linux aide installed` | UBTU-24-90890 |
| `CIS scope - Linux directory joined` | SSSD items |
| `CIS scope - Linux smart card required` | PIV/pam_pkcs11 items |
| `CIS scope - Ubuntu 24.04`, `CIS scope - Ubuntu 26.04` | Version differences: 26.04 has no `pam_lastlog` and no `/etc/timezone`, and defaults to YESCRYPT |

Do not attach fix scripts to infrastructure hosts (databases, clusters, DNS, your Fleet server) without testing. Make role labels for them and use `labels_exclude_any` on the automation.

## Risky settings

1. **SSH lockout.** 11 scripts change sshd (FIPS ciphers, MACs and key exchange, ClientAlive, X11, Banner). Each one writes `/etc/ssh/sshd_config.d/00-stig.conf`, runs `sshd -t` and reverts on failure. The FIPS key exchange list drops curve25519 and the post-quantum key exchange. Test from every place you SSH in from.
2. **Firewall (UBTU-24-100310).** ufw with default deny can cut any service port you did not allow. The script allows 22 and every port that is listening when it runs. Run it on one host per role first.
3. **sudo NOPASSWD (UBTU-24-300021).** Cloud images add `ubuntu ALL=(ALL) NOPASSWD:ALL` and set no password. Removing the rule breaks sudo and automation, so this one is manual.
4. **PAM** (faillock with `unlock_time=0`, faildelay, nullok, pwquality). A broken `common-auth` blocks console and sudo password use. Keep a root console open while you test.
5. **auditd with `-e 2` and AIDE.** CPU, IO and disk load on busy hosts. `-e 2` makes the rules immutable until reboot. The AIDE script excludes large data directories and runs at low priority.
6. **Time sync.** chrony replaces systemd-timesyncd and needs a reachable NTP source. `makestep 1 -1` steps the clock whenever it drifts more than 1 second.
7. **Not automated:** FIPS mode (Ubuntu Pro and a reboot; not available on 26.04), full-disk encryption and the GRUB password.

## Why a policy can show "no data"

Fleet stores no result when the query errors on the host.

- **`file_lines` on a missing file.** `file_lines` comes with the fleetd extension and errors with "file does not exist". Of the 116 queries that use it, 75 read the path from the `file` table first and join with `CROSS JOIN`, so a missing file fails the policy instead of erroring. The other 41 read `file_lines` directly and show no data when their file is missing (for example the chrony checks on hosts without chrony). The safe pattern:
  ```sql
  SELECT 1 FROM file f CROSS JOIN file_lines fl ON fl.path = f.path
  WHERE (f.path = '/etc/audit/audit.rules' OR f.path LIKE '/etc/audit/rules.d/%')
    AND f.type = 'regular'
    AND fl.line LIKE '%-w /etc/passwd%' AND fl.line LIKE '%-p wa%';
  ```
  With a plain `JOIN`, SQLite can query `file_lines` first and get the same error. `f.type = 'regular'` skips directories such as `sshd_config.d`.
- **The fleetd extension is not loaded.** Hosts where osqueryd crashes or the extension does not register have no `file_lines` table. Every policy that uses it shows no data until the extension is back.

## How this was tested

- **Scripts:** all 158 check functions ran read-only through Fleet on Ubuntu 24.04 and 26.04 hosts. Wherever Fleet had data, 86 matched Fleet. 3 differed because of query defects, which have since been fixed. For the rest, Fleet had no data to compare with.
- **Queries:** 76 policies in `policies.yaml` were rewritten after testing, mostly for the `file_lines` pattern above and for audit rules that use `-F perm=x`.
- **Not tested:** fix mode for any script.
