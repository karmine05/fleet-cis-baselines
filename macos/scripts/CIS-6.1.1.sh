#!/bin/sh
# CIS-6.1.1: Audit Show All Filename Extensions
# Fleet policy: CIS 6.1.1 (L1) Audit Show All Filename Extensions (Manual)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# local accounts with a home under /Users (same set the policies join through the users table)
mac_users() { dscl . -list /Users NFSHomeDirectory | awk '$2 ~ /^\/Users\// && $2 != "/Users/Shared" {print $1 ":" $2}'; }
plist_is() { [ "$(/usr/bin/defaults read "$1" "$2" 2>/dev/null)" = "$3" ]; }
# users_plist_is REL_PATH KEY WANT: every user's plist has KEY == WANT
users_plist_is() { for u in $(mac_users); do plist_is "${u#*:}/$1" "$2" "$3" || return 1; done; }
# users_write DOMAIN_OR_REL_PATH KEY TYPE VALUE: write as each user so cfprefsd sees it
users_write() { for u in $(mac_users); do n=${u%%:*}; h=${u#*:}
  case "$1" in /*|Library/*) d="$h/${1#/}" ;; *) d="$1" ;; esac
  sudo -u "$n" /usr/bin/defaults write "$d" "$2" "-$3" "$4"; done; }

check() (
  users_plist_is Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions 1
)

apply() {
  users_write NSGlobalDomain AppleShowAllExtensions bool true
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
