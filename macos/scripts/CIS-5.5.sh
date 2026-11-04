#!/bin/sh
# CIS-5.5: Ensure a Separate Timestamp Is Enabled for Each User/tty Combo
# Fleet policy: CIS 5.5 (L1) Ensure a Separate Timestamp Is Enabled for Each User/tty Combo (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# sudo_drop FILE LINE: add a sudoers drop-in line, validated by visudo
sudo_drop() { f=/etc/sudoers.d/$1; touch "$f"; grep -qxF "$2" "$f" || echo "$2" >> "$f"
  chown root:wheel "$f"; chmod 440 "$f"; chown root:wheel /etc/sudoers.d
  visudo -cf "$f" >/dev/null || { echo "visudo rejected $f; removing"; rm -f "$f"; return 1; }; }

check() (
  sudo -V | grep -q 'Type of authentication timestamp record: tty'
)

apply() {
  sudo_drop 10_cis_timestamp 'Defaults timestamp_type=tty'
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
