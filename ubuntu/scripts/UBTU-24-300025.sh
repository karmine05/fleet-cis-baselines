#!/bin/sh
# UBTU-24-300025: Must disable the x86 Ctrl-Alt-Delete key sequence if a graphical user interface is installed
# Fleet policy: CIS 1.68 UBTU-24-300025 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  systemctl is-enabled ctrl-alt-del.target 2>/dev/null | grep -q masked && { [ ! -d /etc/dconf/db ] || grep -rqs "logout=''" /etc/dconf/db/local.d/; }
)

apply() {
  systemctl mask ctrl-alt-del.target; if [ -d /etc/dconf/db ]; then mkdir -p /etc/dconf/db/local.d; printf '%s\n' '[org/gnome/settings-daemon/plugins/media-keys]' "logout=''" > /etc/dconf/db/local.d/00-stig-ctrlaltdel; dconf update; fi
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
