#!/bin/sh
# CIS-3.5: Ensure Access to Audit Records Is Controlled
# Fleet policy: CIS 3.5 (L1) Ensure Access to Audit Records Is Controlled (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -z "$(find /var/audit -type f ! -perm 440 2>/dev/null; find /var/audit -type f \( ! -user root -o ! -group wheel \) 2>/dev/null)" ] && { [ ! -e /etc/security/audit_control ] || [ "$(stat -f %Lp /etc/security/audit_control)" = 400 ]; }
)

apply() {
  chown -R root:wheel /var/audit; find /var/audit -type f -exec chmod 440 {} +; [ -e /etc/security/audit_control ] && chmod 400 /etc/security/audit_control; true
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
