#!/bin/sh
# CIS-3.4: Ensure Security Auditing Retention Is Enabled
# Fleet policy: CIS 3.4 (L1) Ensure Security Auditing Retention Is Enabled (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  grep -E '^\* file /var/log/install.log' /etc/asl/com.apple.install | grep -v all_max= | grep -qE 'ttl=(36[5-9]|3[7-9][0-9]|[4-9][0-9]{2}|[0-9]{4,})'
)

apply() {
  sed -i '' -E '/^\* file \/var\/log\/install.log/ { s/ all_max=[^ ]+//; s/ ttl=[0-9]+//; s/$/ ttl=365/; }' /etc/asl/com.apple.install
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
