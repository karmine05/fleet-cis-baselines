#!/bin/sh
# UBTU-24-90890: Must use cryptographic mechanisms to protect the integrity of audit tools
# Fleet policy: CIS 1.1 UBTU-24-90890 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }

check() (
  grep -hsE '^[^#]*/sbin/auditctl.*sha512' /etc/aide/aide.conf /etc/aide/aide.conf.d/* | grep -q .
)

apply() {
  pkg_ok aide || apt_in aide; for t in auditctl auditd ausearch aureport autrace augenrules; do grep -qE "^/sbin/$t " /etc/aide/aide.conf || echo "/sbin/$t p+i+n+u+g+s+b+acl+xattrs+sha512" >> /etc/aide/aide.conf; done
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
