#!/bin/sh
# UBTU-24-700320: Must be configured so that the Advance Package Tool (APT) removes all software components after updated versions have been installed
# Fleet policy: CIS 1.130 UBTU-24-700320 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  apt-config dump | grep -qi 'Unattended-Upgrade::Remove-Unused-Dependencies "true"' && apt-config dump | grep -qi 'Unattended-Upgrade::Remove-Unused-Kernel-Packages "true"'
)

apply() {
  printf '%s\n' 'Unattended-Upgrade::Remove-Unused-Dependencies "true";' 'Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";' > /etc/apt/apt.conf.d/51stig-unattended
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
