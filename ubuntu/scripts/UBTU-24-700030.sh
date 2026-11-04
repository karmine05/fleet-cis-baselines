#!/bin/sh
# UBTU-24-700030: Must be configured so that the "journalctl" command is not accessible by unauthorized users
# Fleet policy: CIS 1.115 UBTU-24-700030 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# mode_le PATH MAXMODE: true when PATH has no permission bits beyond MAXMODE (octal)
mode_le() { m=$(stat -c %a "$1" 2>/dev/null) || return 1; [ $(( 0$m & ~0$2 & 07777 )) -eq 0 ]; }

check() (
  mode_le /usr/bin/journalctl 740
)

apply() {
  dpkg-statoverride --update --add root root 740 /usr/bin/journalctl 2>/dev/null || chmod 740 /usr/bin/journalctl
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
