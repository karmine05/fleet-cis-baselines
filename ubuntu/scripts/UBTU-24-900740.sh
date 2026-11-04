#!/bin/sh
# UBTU-24-900740: Must generate audit records for successful/unsuccessful attempts to use the kmod command
# Fleet policy: CIS 1.171 UBTU-24-900740 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }
audit_has() { cat /etc/audit/rules.d/*.rules /etc/audit/audit.rules 2>/dev/null | grep -v '^[[:space:]]*#' | grep -qE -- "$1"; }
audit_add() {
  pkg_ok auditd || apt_in auditd || return 1
  f=/etc/audit/rules.d/50-stig.rules; touch "$f"; chmod 640 "$f"
  for r in "$@"; do grep -qxF -- "$r" "$f" || printf '%s\n' "$r" >> "$f"; done
  systemctl enable --now auditd >/dev/null 2>&1
  augenrules --load >/dev/null 2>&1 || echo "augenrules --load failed (rules immutable with -e 2? reboot to load)"
}

check() (
  audit_has '^-w /bin/kmod( |$).*-p x'
)

apply() {
  audit_add '-w /bin/kmod -p x -k modules'
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
