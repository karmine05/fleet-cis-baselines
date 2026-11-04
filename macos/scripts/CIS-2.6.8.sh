#!/bin/sh
# CIS-2.6.8: Ensure an Administrator Password Is Required to Access System-Wide Preferences
# Fleet policy: CIS 2.6.8 (L1) Ensure an Administrator Password Is Required to Access System-Wide Preferences (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  security authorizationdb read system.preferences 2>/dev/null | grep -A1 '<key>shared</key>' | grep -q '<false/>'
)

apply() {
  t=$(mktemp); security authorizationdb read system.preferences > "$t" 2>/dev/null; /usr/bin/defaults write "$t" shared -bool false; security authorizationdb write system.preferences < "$t"; rm -f "$t"
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
