#!/bin/sh
# UBTU-24-700150: Must configure "/var/log/syslog" file with mode "640" or less permissive
# Fleet policy: CIS 1.127 UBTU-24-700150 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# mode_le PATH MAXMODE: true when PATH has no permission bits beyond MAXMODE (octal)
mode_le() { m=$(stat -c %a "$1" 2>/dev/null) || return 1; [ $(( 0$m & ~0$2 & 07777 )) -eq 0 ]; }

check() (
  mode_le /var/log/syslog 640
)

apply() {
  chmod 640 /var/log/syslog
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
