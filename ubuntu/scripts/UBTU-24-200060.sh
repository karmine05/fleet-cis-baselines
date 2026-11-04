#!/bin/sh
# UBTU-24-200060: Must automatically terminate a user session after inactivity timeouts have expired
# Fleet policy: CIS 1.37 UBTU-24-200060 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }



check() (
  grep -hsE '^[[:space:]]*(readonly[[:space:]]+)?TMOUT=[0-9]+' /etc/profile.d/*.sh /etc/bash.bashrc /etc/profile | sed -E 's/.*TMOUT=([0-9]+).*/\1/' | awk '$1 >= 1 && $1 <= 600 {ok=1} END {exit !ok}'
)

apply() {
  printf '%s\n' 'TMOUT=600' 'readonly TMOUT' 'export TMOUT' > /etc/profile.d/99-terminal_tmout.sh; chmod 644 /etc/profile.d/99-terminal_tmout.sh
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
