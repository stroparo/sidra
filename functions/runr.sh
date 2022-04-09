# RUNR solution (stroparo/runr) wrappers

# Prefer these as functions over aliases so scripted subshells will have access:

unalias rr runr >/dev/null 2>&1
runr () { "${ZDRA_HOME:-$HOME/.zdra}"/scripts/runr.sh "$@" ; }
alias rr=runr

unalias rrd runrd >/dev/null 2>&1
runrd () { RUNR_DEBUG=true "${ZDRA_HOME:-$HOME/.zdra}"/scripts/runr.sh "$@" ; }
alias rrd=runrd

unalias rru runrup >/dev/null 2>&1
runrup () { "${ZDRA_HOME:-$HOME/.zdra}"/scripts/runr.sh -u "$@" ; }
alias rru=runrup
