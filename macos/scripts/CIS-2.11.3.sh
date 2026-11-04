#!/bin/sh
# CIS-2.11.3: Ensure a Custom Message for the Login Screen Is Enabled
# Fleet policy: CIS 2.11.3 (L1) Ensure a Custom Message for the Login Screen Is Enabled (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -n "$(/usr/bin/defaults read /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null)" ]
)

apply() {
  /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText 'Authorized use only. Activity may be monitored.'
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
