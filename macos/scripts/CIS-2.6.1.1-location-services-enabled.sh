#!/bin/sh
# CIS-2.6.1.1-location-services-enabled: Ensure Location Services Is Enabled [location-services-enabled]
# Fleet policy: CIS 2.6.1.1 (L2) Ensure Location Services Is Enabled (Automated) [location-services-enabled]
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

plist_is() { [ "$(/usr/bin/defaults read "$1" "$2" 2>/dev/null)" = "$3" ]; }

check() (
  plist_is /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled 1
)

apply() {
  sudo -u _locationd /usr/bin/defaults -currentHost write com.apple.locationd LocationServicesEnabled -bool true; launchctl kickstart -k system/com.apple.locationd
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
