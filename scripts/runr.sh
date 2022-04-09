#!/usr/bin/env bash

PROGNAME="runr.sh"
if ${IGNORE_SSL:-false} ; then IGNORE_SSL_OPTION='-k'; fi


_get_entry_online () {
  bash -c "$(curl ${IGNORE_SSL_OPTION} ${DLOPTEXTRA} -LSf "https://bitbucket.org/stroparo/runr/raw/master/entry.sh" \
    || curl ${IGNORE_SSL_OPTION} ${DLOPTEXTRA} -LSf "https://raw.githubusercontent.com/stroparo/runr/master/entry.sh")"
}


_runr () {
  typeset runr_entry_code

  if ${RUNR_DEBUG:-false} && [ -f "${DEV}/runr/entry.sh" ] ; then
    if [ -d "${HOME}/.runr" ] && ! cp -p -r "${HOME}/.runr" "${HOME}/.runr-$(date '+%Y%m%d-%OH%OM')" ; then
      echo "${PROGNAME:+$PROGNAME: }FATAL: Could not backup '${HOME}/.runr'." 1>&2
      return 1
    fi
    if ! rm -f -r "${HOME}/.runr" || ! cp -r -v "${DEV}/runr" "${HOME}/.runr" ; then
      echo "${PROGNAME:+$PROGNAME: }FATAL: Could not copy '${DEV}/runr' to '${HOME}/.runr'." 1>&2
      return 1
    fi
  fi

  if [ -f "${HOME}/.runr/entry.sh" ] ; then
    runr_entry_code="$(cat "${HOME}/.runr/entry.sh")"
  else
    runr_entry_code="$(_get_entry_online)"
  fi

  if [ -n "${runr_entry_code}" ] ; then
    bash -c "${runr_entry_code}" entry.sh "$@"
  else
    echo "${PROGNAME:+$PROGNAME: }FATAL: No runr entry script code could be retrieved." 1>&2
    return 1
  fi
}


_runr "$@"
exit $?

