#!/bin/sh
# UBTU-24-600180: Must synchronize internal information system clocks to the authoritative time source when the time difference is greater than one second
# Fleet policy: CIS 1.109 UBTU-24-600180 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }

check() (
  grep -hsE '^[[:space:]]*makestep[[:space:]]+1[[:space:]]+-1' /etc/chrony/chrony.conf /etc/chrony/conf.d/*.conf | grep -q .
)

apply() {
  pkg_ok chrony || apt_in chrony; mkdir -p /etc/chrony/conf.d; echo 'makestep 1 -1' > /etc/chrony/conf.d/stig.conf; systemctl restart chrony
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
