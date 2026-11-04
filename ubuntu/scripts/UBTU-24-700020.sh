#!/bin/sh
# UBTU-24-700020: Must generate system journal entries without revealing information that could be exploited by adversaries
# Fleet policy: CIS 1.114 UBTU-24-700020 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# mode_le PATH MAXMODE: true when PATH has no permission bits beyond MAXMODE (octal)
mode_le() { m=$(stat -c %a "$1" 2>/dev/null) || return 1; [ $(( 0$m & ~0$2 & 07777 )) -eq 0 ]; }

check() (
  for d in /run/log/journal /var/log/journal; do [ -d $d ] || continue; mode_le $d 2750 || exit 1; done
)

apply() {
  printf '%s\n' 'z /run/log/journal 2750 root systemd-journal - -' 'z /var/log/journal 2750 root systemd-journal - -' > /etc/tmpfiles.d/systemd-journal-stig.conf; systemd-tmpfiles --create /etc/tmpfiles.d/systemd-journal-stig.conf
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
