#!/bin/sh
# UBTU-24-100310: Must enable and run the Uncomplicated Firewall (ufw)
# Fleet policy: CIS 1.12 UBTU-24-100310 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }
unit_active() { systemctl is-active --quiet "$1"; }

check() (
  unit_active ufw.service && ufw status | grep -q 'Status: active'
)

apply() {
  pkg_ok ufw || apt_in ufw; ufw allow 22/tcp >/dev/null; for p in $(ss -lntuH | awk '$5 !~ /^(127\.|\[::1\])/ {n=split($5,a,":"); print a[n] "/" $1}' | sort -u); do ufw allow "$p" >/dev/null; done; ufw --force enable; systemctl enable --now ufw.service
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
