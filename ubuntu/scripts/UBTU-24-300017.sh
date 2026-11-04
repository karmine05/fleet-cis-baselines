#!/bin/sh
# UBTU-24-300017: Must enforce a delay of at least four seconds between logon prompts following a failed logon attempt
# Fleet policy: CIS 1.63 UBTU-24-300017 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  grep -qE '^[^#]*pam_faildelay\.so.*delay=([4-9][0-9]{6}|[0-9]{8,})' /etc/pam.d/common-auth
)

apply() {
  sed -i '/pam_faildelay\.so/d' /etc/pam.d/common-auth; sed -i '1i auth required pam_faildelay.so delay=4000000' /etc/pam.d/common-auth
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
