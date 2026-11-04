#!/bin/sh
# CIS-2.3.3.10: Ensure Bluetooth Sharing Is Disabled
# Fleet policy: CIS 2.3.3.10 (L1) Ensure Bluetooth Sharing Is Disabled (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# local accounts with a home under /Users (same set the policies join through the users table)
mac_users() { dscl . -list /Users NFSHomeDirectory | awk '$2 ~ /^\/Users\// && $2 != "/Users/Shared" {print $1 ":" $2}'; }

check() (
  [ -z "$(for u in $(mac_users); do for f in "${u#*:}"/Library/Preferences/ByHost/com.apple.Bluetooth.*.plist; do [ -f "$f" ] && [ "$(/usr/bin/defaults read "$f" PrefKeyServicesEnabled 2>/dev/null)" = 1 ] && echo x; done; done)" ]
)

apply() {
  for u in $(mac_users); do sudo -u "${u%%:*}" /usr/bin/defaults -currentHost write com.apple.Bluetooth PrefKeyServicesEnabled -bool false; done
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
