#!/bin/sh
# CIS-3.2: Ensure Security Auditing Flags For User-Attributable Events Are Configured Per Local Organizational Requirements
# Fleet policy: CIS 3.2 (L2) Ensure Security Auditing Flags For User-Attributable Events Are Configured Per Local Organizational Requirements (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

audit_on() { [ -f /etc/security/audit_control ] || cp /etc/security/audit_control.example /etc/security/audit_control
  chown root:wheel /etc/security/audit_control; chmod 400 /etc/security/audit_control
  launchctl enable system/com.apple.auditd
  launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null; audit -s 2>/dev/null; true; }

check() (
  grep -E '^flags:' /etc/security/audit_control 2>/dev/null | awk '/-fm/ && /ad/ && /-ex/ && /aa/ && /-fr/ && /lo/ && /-fw/ {ok=1} /-all/ && /ad/ && /aa/ && /lo/ {ok=1} END {exit !ok}'
)

apply() {
  audit_on; sed -i '' 's/^flags:.*/flags:-fm,ad,-ex,aa,-fr,lo,-fw/' /etc/security/audit_control; audit -s
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
