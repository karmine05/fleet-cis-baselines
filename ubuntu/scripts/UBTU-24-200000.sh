#!/bin/sh
# UBTU-24-200000: Must limit the number of concurrent sessions to ten for all accounts and/or account types
# Fleet policy: CIS 1.34 UBTU-24-200000 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  grep -hsE '^[^#]*\bmaxlogins[[:space:]]+[0-9]+' /etc/security/limits.conf /etc/security/limits.d/*.conf | awk '{if ($NF+0 > 10 || $NF+0 < 1) bad=1; n++} END {exit (n && !bad) ? 0 : 1}'
)

apply() {
  printf '%s\n' '* hard maxlogins 10' > /etc/security/limits.d/90-stig-maxlogins.conf
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
