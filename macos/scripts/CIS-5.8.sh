#!/bin/sh
# CIS-5.8: Ensure a Login Window Banner Exists
# Fleet policy: CIS 5.8 (L2) Ensure a Login Window Banner Exists (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -e /Library/Security/PolicyBanner.txt ] || [ -e /Library/Security/PolicyBanner.rtf ] || [ -e /Library/Security/PolicyBanner.rtfd ]
)

apply() {
  printf '%s\n' 'Authorized use only. Activity may be monitored.' > /Library/Security/PolicyBanner.txt; chown root:wheel /Library/Security/PolicyBanner.txt; chmod 644 /Library/Security/PolicyBanner.txt
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
