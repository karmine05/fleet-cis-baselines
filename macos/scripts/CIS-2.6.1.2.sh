#!/bin/sh
# CIS-2.6.1.2: Ensure 'Show Location Icon in Control Center when System Services Request Your Location' Is Enabled
# Fleet policy: CIS 2.6.1.2 (L2) Ensure 'Show Location Icon in Control Center when System Services Request Your Location' Is Enabled (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

plist_is() { [ "$(/usr/bin/defaults read "$1" "$2" 2>/dev/null)" = "$3" ]; }

check() (
  plist_is /Library/Preferences/com.apple.locationmenu ShowSystemServices 1
)

apply() {
  /usr/bin/defaults write /Library/Preferences/com.apple.locationmenu ShowSystemServices -bool true
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
