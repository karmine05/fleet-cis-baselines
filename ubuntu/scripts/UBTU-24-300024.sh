#!/bin/sh
# UBTU-24-300024: Must display the date and time of the last successful account logon upon logon
# Fleet policy: CIS 1.67 UBTU-24-300024 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  grep -qE '^[^#]*pam_lastlog2?\.so' /etc/pam.d/login
)

apply() {
  [ -e /usr/lib/x86_64-linux-gnu/security/pam_lastlog.so ] && m=pam_lastlog.so || m=pam_lastlog2.so; sed -i "1i session required $m showfailed" /etc/pam.d/login
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
