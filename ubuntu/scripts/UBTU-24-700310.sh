#!/bin/sh
# UBTU-24-700310: Must implement address space layout randomization to protect its memory from unauthorized code execution
# Fleet policy: CIS 1.129 UBTU-24-700310 (Automated)
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
  sysctl_is kernel.randomize_va_space 2
)

apply() {
  sysctl_set kernel.randomize_va_space 2; grep -rl 'randomize_va_space' /etc/sysctl.conf /etc/sysctl.d 2>/dev/null | grep -v 99-stig | xargs -r sed -i '/randomize_va_space/d'
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
