# Process management routines

pgr () { ps -ef | egrep -i "$1" | egrep -v "grep.*(${1})" ; }
psfu () { ps -fu "${UID:-$(id -u)}" -U "${UID:-$(id -u)}" ; }
psuser () { ps -ef | grep "^${USER}" ; }

pgrnosh () {
  ps -ef \
    | egrep -v -w '([bd]a|c|fi|k|z)sh|sshd' \
    | egrep -i "${1}" \
    | egrep -v "grep.*(${1})"
}
