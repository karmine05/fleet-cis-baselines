#!/bin/sh
# CIS-5.7: Ensure an Administrator Account Cannot Login to Another User's Active and Locked Session
# Fleet policy: CIS 5.7 (L1) Ensure an Administrator Account Cannot Login to Another User's Active and Locked Session (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  security authorizationdb read system.login.screensaver 2>/dev/null | grep -A1 '<key>rule</key>' | grep -q '<string>authenticate-session-owner</string>'
)

apply() {
  security authorizationdb write system.login.screensaver authenticate-session-owner
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
