#!/bin/sh
# UBTU-24-102010: Must initiate session audits at system startup
# Fleet policy: CIS 1.33 UBTU-24-102010 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  awk '/^[[:space:]]*linux/ {n++; if ($0 !~ /audit=1/) bad=1} END {exit !(n && !bad)}' /boot/grub/grub.cfg
)

apply() {
  grep -q 'audit=1' /etc/default/grub || sed -i -E 's/^(GRUB_CMDLINE_LINUX=")/\1audit=1 /' /etc/default/grub; update-grub
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
