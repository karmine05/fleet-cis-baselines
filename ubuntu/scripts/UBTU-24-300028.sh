#!/bin/sh
# UBTU-24-300028: Must not allow accounts configured in Pluggable Authentication Modules (PAM) with blank or null passwords
# Fleet policy: CIS 1.71 UBTU-24-300028 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  ! grep -qE '^[^#]*nullok' /etc/pam.d/common-auth /etc/pam.d/common-password
)

apply() {
  sed -i -E '/^[^#]/ s/[[:space:]]+nullok\b//' /etc/pam.d/common-auth /etc/pam.d/common-password
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
