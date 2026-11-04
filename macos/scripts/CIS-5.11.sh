#!/bin/sh
# CIS-5.11: Ensure Logging Is Enabled for Sudo
# Fleet policy: CIS 5.11 (L1) Ensure Logging Is Enabled for Sudo (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# sudo_drop FILE LINE: add a sudoers drop-in line, validated by visudo
sudo_drop() { f=/etc/sudoers.d/$1; touch "$f"; grep -qxF "$2" "$f" || echo "$2" >> "$f"
  chown root:wheel "$f"; chmod 440 "$f"; chown root:wheel /etc/sudoers.d
  visudo -cf "$f" >/dev/null || { echo "visudo rejected $f; removing"; rm -f "$f"; return 1; }; }

check() (
  cat /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -v '^#' | grep 'Defaults' | grep 'log_allowed' | grep -vq '!log_allowed'
)

apply() {
  sudo_drop 10_cis_logging 'Defaults log_allowed'
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
