#!/bin/sh
# UBTU-24-100840: The operating system SSH server must be configured to use only FIPS-validated key exchange algorithms
# Fleet policy: CIS 1.26 UBTU-24-100840 (Automated)
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
sshd_get() { sshd -T 2>/dev/null | awk -v k="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" '$1 == k { $1 = ""; sub(/^ /, ""); print; exit }'; }
sshd_cmp() { v=$(sshd_get "$1"); [ -n "$v" ] && cmp_val "$v" "$2" "$3"; }
# Drop-in sorts before 60-cloudimg-settings.conf; sshd keeps the first value it reads.
SSHD_DROP=/etc/ssh/sshd_config.d/00-stig.conf
sshd_set() {
  [ -f "$SSHD_DROP" ] && cp -p "$SSHD_DROP" "$SSHD_DROP.bak"
  kv_set "$SSHD_DROP" "$1" "$2" " "; chmod 600 "$SSHD_DROP"
  if sshd -t; then
    rm -f "$SSHD_DROP.bak"; systemctl try-reload-or-restart ssh.service
  else
    echo "sshd -t failed; reverting $SSHD_DROP"
    if [ -f "$SSHD_DROP.bak" ]; then mv "$SSHD_DROP.bak" "$SSHD_DROP"; else rm -f "$SSHD_DROP"; fi
    return 1
  fi
}

check() (
  sshd_cmp KexAlgorithms subset "ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group14-sha256"
)

apply() {
  sshd_set KexAlgorithms "ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group14-sha256"
}

case "${1:-$DEFAULT_MODE}" in
  --check) if check; then echo COMPLIANT; exit 0; else echo NOT_COMPLIANT; exit 1; fi ;;
  --apply)
    if check; then echo "already compliant"; exit 0; fi
    apply || { echo "apply step failed"; exit 1; }
    if check; then echo REMEDIATED; exit 0; else echo "still not compliant"; exit 1; fi ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac
