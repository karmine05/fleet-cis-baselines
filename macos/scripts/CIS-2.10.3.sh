#!/bin/sh
# CIS-2.10.3: Ensure Wake for Network Access Is Disabled
# Fleet policy: CIS 2.10.3 (L1) Ensure Wake for Network Access Is Disabled (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# pm_all KEY OP WANT: every power source's pmset value satisfies OP
pm_all() { pmset -g custom | awk -v k="$1" -v op="$2" -v w="$3" '$1 == k { n++; v = $2 + 0
  if ((op == "eq" && v != w) || (op == "le" && v > w) || (op == "ge" && v < w)) bad = 1 } END { exit !(n && !bad) }'; }

check() (
  pm_all womp eq 0
)

apply() {
  pmset -a womp 0
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
