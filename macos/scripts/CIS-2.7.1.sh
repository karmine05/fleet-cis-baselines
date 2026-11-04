#!/bin/sh
# CIS-2.7.1: Ensure Screen Saver Corners Are Secure
# Fleet policy: CIS 2.7.1 (L2) Ensure Screen Saver Corners Are Secure (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# local accounts with a home under /Users (same set the policies join through the users table)
mac_users() { dscl . -list /Users NFSHomeDirectory | awk '$2 ~ /^\/Users\// && $2 != "/Users/Shared" {print $1 ":" $2}'; }

check() (
  [ -z "$(for u in $(mac_users); do for c in tl tr bl br; do [ "$(/usr/bin/defaults read "${u#*:}/Library/Preferences/com.apple.dock.plist" wvous-$c-corner 2>/dev/null)" = 6 ] && echo x; done; done)" ]
)

apply() {
  for u in $(mac_users); do for c in tl tr bl br; do [ "$(sudo -u "${u%%:*}" /usr/bin/defaults read com.apple.dock wvous-$c-corner 2>/dev/null)" = 6 ] && sudo -u "${u%%:*}" /usr/bin/defaults write com.apple.dock wvous-$c-corner -int 1; done; done; true
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
