#!/bin/sh
# CIS-5.1.1: Ensure Home Folders Are Secure
# Fleet policy: CIS 5.1.1 (L1) Ensure Home Folders Are Secure (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -z "$(find /Users -mindepth 1 -maxdepth 1 -type d ! -name Shared ! -name Guest ! -perm 700 ! -perm 701 ! -perm 710 ! -perm 711)" ]
)

apply() {
  find /Users -mindepth 1 -maxdepth 1 -type d ! -name Shared ! -name Guest -exec chmod og-rw {} +
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
