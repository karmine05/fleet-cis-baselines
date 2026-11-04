#!/bin/sh
# UBTU-24-200610: Must automatically lock an account until the locked account is released by an administrator when three unsuccessful logon attempts have been made
# Fleet policy: CIS 1.47 UBTU-24-200610 (Automated)
# Usage: $0 [--check|--apply]  --check: exit 0 = compliant, 1 = not compliant (read-only). --apply: remediate, then re-check.
# Fleet runs scripts without arguments, so DEFAULT_MODE decides what a Fleet run does. Set it to --apply only for a remediation run.
DEFAULT_MODE=--check
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 2; }

pkg_ok() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'; }
apt_in() { DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; }
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

check() (
  grep -qE '^[^#]*pam_faillock\.so' /etc/pam.d/common-auth && kv_cmp /etc/security/faillock.conf deny = le 3
)

apply() {
  pkg_ok libpam-modules || apt_in libpam-modules; printf '%s\n' 'Name: Enforce faillock' 'Default: yes' 'Priority: 1024' 'Auth-Type: Primary' 'Auth:' '        [default=die] pam_faillock.so authfail' 'Auth-Initial:' '        [default=die] pam_faillock.so authfail' > /usr/share/pam-configs/faillock; printf '%s\n' 'Name: Notify faillock' 'Default: yes' 'Priority: 1025' 'Auth-Type: Primary' 'Auth:' '        requisite pam_faillock.so preauth' > /usr/share/pam-configs/faillock_notify; pam-auth-update --package --enable faillock faillock_notify; kv_set /etc/security/faillock.conf deny 3 =; kv_set /etc/security/faillock.conf fail_interval 900 =; kv_set /etc/security/faillock.conf unlock_time 0 =; grep -qx audit /etc/security/faillock.conf || echo audit >> /etc/security/faillock.conf; grep -qx silent /etc/security/faillock.conf || echo silent >> /etc/security/faillock.conf
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
