#!/bin/sh
# CIS-3.4-auditd-enabled: Ensure Security Auditing Retention Is Enabled [auditd-enabled]
# Fleet policy: CIS 3.4 (L1) Ensure Security Auditing Retention Is Enabled (Automated) [auditd-enabled]
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

audit_on() { [ -f /etc/security/audit_control ] || cp /etc/security/audit_control.example /etc/security/audit_control
  chown root:wheel /etc/security/audit_control; chmod 400 /etc/security/audit_control
  launchctl enable system/com.apple.auditd
  launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null; audit -s 2>/dev/null; true; }

check() (
  launchctl print system/com.apple.auditd 2>/dev/null | grep -q 'state = running' || pgrep -qx auditd
)

apply() {
  audit_on
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
