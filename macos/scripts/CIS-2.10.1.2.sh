#!/bin/sh
# CIS-2.10.1.2: Ensure Sleep and Display Sleep Is Enabled on Apple Silicon Devices
# Fleet policy: CIS 2.10.1.2 (L2) Ensure Sleep and Display Sleep Is Enabled on Apple Silicon Devices (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# pm_all KEY OP WANT: every power source's pmset value satisfies OP
pm_all() { pmset -g custom | awk -v k="$1" -v op="$2" -v w="$3" '$1 == k { n++; v = $2 + 0
  if ((op == "eq" && v != w) || (op == "le" && v > w) || (op == "ge" && v < w)) bad = 1 } END { exit !(n && !bad) }'; }

check() (
  [ "$(uname -m)" != arm64 ] || { pm_all sleep le 15 && pm_all displaysleep le 10 && [ "$(pmset -g custom | awk '$1=="displaysleep"{print $2; exit}')" -le "$(pmset -g custom | awk '$1=="sleep"{print $2; exit}')" ]; }
)

apply() {
  pmset -a sleep 15 displaysleep 10
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
