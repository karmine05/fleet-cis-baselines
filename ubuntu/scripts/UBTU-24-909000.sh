#!/bin/sh
# UBTU-24-909000: The operating system's audit system must protect auditing rules from unauthorized change
# Fleet policy: CIS 1.188 UBTU-24-909000 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }
audit_has() { cat /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null | grep -v '^[[:space:]]*#' | grep -qE -- "$1"; }

check() (
  audit_has '^-e 2'
)

apply() {
  pkg_ok auditd || apt_in auditd; echo '-e 2' > /etc/audit/rules.d/99-finalize.rules; augenrules --load
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
