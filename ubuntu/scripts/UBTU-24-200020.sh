#!/bin/sh
# UBTU-24-200020: Must initiate a graphical session lock after 15 minutes of inactivity
# Fleet policy: CIS 1.35 UBTU-24-200020 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  grep -rqsE '^[[:space:]]*idle-delay[[:space:]]*=[[:space:]]*uint32[[:space:]]+([1-9][0-9]?|[1-8][0-9]{2}|900)$' /etc/dconf/db/local.d/
)

apply() {
  mkdir -p /etc/dconf/db/local.d; printf '%s\n' '[org/gnome/desktop/session]' 'idle-delay=uint32 900' > /etc/dconf/db/local.d/00-stig-idle; dconf update
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
