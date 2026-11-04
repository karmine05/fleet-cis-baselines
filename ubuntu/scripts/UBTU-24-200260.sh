#!/bin/sh
# UBTU-24-200260: Must disable account identifiers (individuals, groups, roles, and devices) after 35 days of inactivity
# Fleet policy: CIS 1.40 UBTU-24-200260 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

# cmp_val VALUE OP WANT  (eq|ieq|le|ge|has|subset)
cmp_val() {
  case "$2" in
    eq) [ "$1" = "$3" ] ;;
    ieq) [ "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" = "$(printf '%s' "$3" | tr 'A-Z' 'a-z')" ] ;;
    le) [ "$1" -le "$3" ] 2>/dev/null ;;
    ge) [ "$1" -ge "$3" ] 2>/dev/null ;;
    has) case "$1" in *"$3"*) true ;; *) false ;; esac ;;
    subset) for a in $(printf '%s' "$1" | tr ',' ' '); do
              case ",$3," in *",$a,"*) ;; *) return 1 ;; esac; done ;;
    *) return 2 ;;
  esac
}
# kv_get FILE KEY SEP -> last uncommented value; SEP is "=" (key = value) or " " (KEY value)
kv_get() {
  [ -r "$1" ] || return 1
  awk -v k="$2" -v s="$3" 'BEGIN { k = tolower(k) }
    /^[ \t]*#/ { next }
    { if (s == "=") { n = index($0, "="); if (!n) next; key = substr($0, 1, n - 1); val = substr($0, n + 1) }
      else { key = $1; val = $0; sub(/^[ \t]*[^ \t]+[ \t]*/, "", val) }
      gsub(/^[ \t]+|[ \t]+$/, "", key); gsub(/^[ \t]+|[ \t]+$/, "", val)
      if (tolower(key) == k) { v = val; f = 1 } }
    END { if (!f) exit 1; print v }' "$1"
}
kv_cmp() { v=$(kv_get "$1" "$2" "$3") || return 1; cmp_val "$v" "$4" "$5"; }

check() (
  kv_cmp /etc/default/useradd INACTIVE "=" le "35"
)

apply() {
  useradd -D -f 35
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
