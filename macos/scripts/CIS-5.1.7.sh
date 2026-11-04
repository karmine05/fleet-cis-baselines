#!/bin/sh
# CIS-5.1.7: Ensure No World Writable Folders Exist in the Library Folder
# Fleet policy: CIS 5.1.7 (L2) Ensure No World Writable Folders Exist in the Library Folder (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  [ -z "$(for d in /Library/*/; do d=${d%/}; [ -d "$d" ] || continue; xattr -p com.apple.rootless "$d" >/dev/null 2>&1 && continue; find "$d" -maxdepth 0 -perm -0002 ! -perm -1000; done)" ]
)

apply() {
  for d in /Library/*/; do d=${d%/}; xattr -p com.apple.rootless "$d" >/dev/null 2>&1 && continue; [ -n "$(find "$d" -maxdepth 0 -perm -0002 ! -perm -1000)" ] && chmod o-w "$d"; done; true
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
