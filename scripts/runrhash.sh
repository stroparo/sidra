#!/usr/bin/env bash

PROGNAME="runrhash.sh"

# Purpose:
# Rehash runr repository from the workspace ($DEV i.e. $DEV/runr) and
# seize the moment also to run any recipes in arguments, if any.


# Globals:

: ${DEV:=$HOME/workspace}

unset ignore_ssl_option
if ${IGNORE_SSL:-false} ; then
  ignore_ssl_option='-k'
fi


# Main:

if [ -d ~/.runr ] && ! mv -v ~/.runr ~/.runr.$(date '+%Y%m%d-%OH%OM%OS') ; then
  echo "${PROGNAME:+$PROGNAME: }FATAL: Could not backup '${HOME}/.runr'." 1>&2
  return 1
fi

if [ -d "$DEV"/runr ] && cp -a "${DEV}"/runr ~/.runr && [ -f ~/.runr/entry.sh ] ; then
  chmod 755 ~/.runr/entry.sh
  cd ~/.runr \
    && [[ $PWD = *.runr ]] \
    && bash -c "$(cat ./entry.sh)" entry.sh "$@"
else
  bash -c "$(curl ${ignore_ssl_option} ${DLOPTEXTRA} -LSf "https://bitbucket.org/stroparo/runr/raw/master/entry.sh" \
    || curl ${ignore_ssl_option} ${DLOPTEXTRA} -LSf "https://raw.githubusercontent.com/stroparo/runr/master/entry.sh")" \
    entry.sh "$@"
fi
