#!/bin/sh
# UBTU-24-600190: Must be configured to use TCP syncookies
# Fleet policy: CIS 1.110 UBTU-24-600190 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# kv_set FILE KEY VALUE SEP: replace uncommented KEY lines in place, else append
kv_set() {
  mkdir -p "$(dirname "$1")"; [ -f "$1" ] || : > "$1"
  if [ "$4" = "=" ]; then l="$2 = $3"; else l="$2 $3"; fi
  if grep -qiE "^[[:space:]]*$2([[:space:]]|=)" "$1"; then
    sed -i -E "s#^[[:space:]]*$2([[:space:]]|=).*#$l#I" "$1"
  else
    printf '%s\n' "$l" >> "$1"
  fi
}
sysctl_is() { [ "$(sysctl -n "$1" 2>/dev/null)" = "$2" ]; }
sysctl_set() { kv_set /etc/sysctl.d/99-stig.conf "$1" "$2" "="; sysctl -q -w "$1=$2"; }

check() (
  sysctl_is net.ipv4.tcp_syncookies 1
)

apply() {
  sysctl_set net.ipv4.tcp_syncookies 1
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
