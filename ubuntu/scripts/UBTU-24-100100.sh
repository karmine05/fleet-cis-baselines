#!/bin/sh
# UBTU-24-100100: Must use a file integrity tool to verify correct operation of all security functions
# Fleet policy: CIS 1.6 UBTU-24-100100 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }

check() (
  pkg_ok aide
)

apply() {
  apt_in aide aide-common || exit 1; printf '%s\n' '!/var/lib/docker' '!/var/lib/containerd' '!/var/lib/wazuh-indexer' '!/var/lib/opensearch' > /etc/aide/aide.conf.d/99_stig_excludes; systemd-run --unit=stig-aideinit nice -n 19 ionice -c3 aideinit -y -f
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
