#!/bin/sh
# UBTU-24-300013: Must have system commands group-owned by "root" or a system account
# Fleet policy: CIS 1.60 UBTU-24-300013 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -z "$(find /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin -xdev -maxdepth 1 -type f ! -group root ! -perm -2000 2>/dev/null | head -n 1)" ]
)

apply() {
  find /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin -xdev -maxdepth 1 -type f ! -group root ! -perm -2000 -exec chgrp root {} +
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
