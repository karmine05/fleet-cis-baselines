#!/bin/sh
# UBTU-24-700010: Must generate error messages that provide information necessary for corrective actions without revealing information that could be exploited by adversaries
# Fleet policy: CIS 1.113 UBTU-24-700010 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -z "$(find /var/log -xdev -type f -perm /137 ! -name '*[bw]tmp*' ! -name '*lastlog*' 2>/dev/null | head -n 1)" ]
)

apply() {
  find /var/log -xdev -type f -perm /137 ! -name '*[bw]tmp*' ! -name '*lastlog*' -exec chmod u-x,g-wx,o-rwx {} +
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
