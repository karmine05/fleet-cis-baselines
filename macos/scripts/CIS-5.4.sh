#!/bin/sh
# CIS-5.4: Ensure the Sudo Timeout Period Is Set to Zero
# Fleet policy: CIS 5.4 (L1) Ensure the Sudo Timeout Period Is Set to Zero (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# sudo_drop FILE LINE: add a sudoers drop-in line, validated by visudo
sudo_drop() { f=/etc/sudoers.d/$1; touch "$f"; grep -qxF "$2" "$f" || echo "$2" >> "$f"
  chown root:wheel "$f"; chmod 440 "$f"; chown root:wheel /etc/sudoers.d
  visudo -cf "$f" >/dev/null || { echo "visudo rejected $f; removing"; rm -f "$f"; return 1; }; }

check() (
  [ "$(stat -f '%u:%g' /etc/sudoers.d)" = 0:0 ] && sudo -V | grep -q 'Authentication timestamp timeout: 0.0 minutes'
)

apply() {
  sudo_drop 10_cis_timestamp 'Defaults timestamp_timeout=0'
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
