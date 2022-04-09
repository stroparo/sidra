#!/usr/bin/env bash

# Project / License at https://github.com/stroparo/sidra

# Purpose: Rehash this scripting library's plugins

typeset PROGNAME="zdrahashplugins.sh"


_load_zdra () {
  typeset ZDRA_CURRENT_HOME="${ZDRA_HOME:-$HOME/.zdra}"
  if [ -z "${ZDRA_VERSION}" ] \
    && ! . "${ZDRA_CURRENT_HOME}/zdra.sh" "${ZDRA_CURRENT_HOME}" >/dev/null 2>&1
  then
    echo 1>&2
    echo "SIDRA Scripting Library could not be loaded. Fix it and call this again." 1>&2
    echo "Commands to install the Scripting Library:" 1>&2
    echo "sh -c \"\$(curl -LSfs 'https://raw.githubusercontent.com/stroparo/sidra/master/setup.sh')\"" 1>&2
    echo "sh -c \"\$(wget -O - 'https://raw.githubusercontent.com/stroparo/sidra/master/setup.sh')\"" 1>&2
    echo 1>&2
    exit 1
  fi
  if [ ! -d "$ZDRA_HOME" ] ; then
    echo "${PROGNAME:+$PROGNAME: }FATAL: No ZDRA_HOME='$ZDRA_HOME' dir present." 1>&2
    exit 1
  fi
}
_load_zdra


_set_global_defaults () {
  if [ -z "${DEV}" ] && [ -d "${HOME}/workspace" ] ; then
    export DEV="${HOME}/workspace"
  fi
}


_skip_if_no_plugins_file () {
  # Although SIDRA Scripting Library enforces the existence of this file this is
  # just to inform in case this ever occurs eg the plugins file had
  # not been created because of some permission issue etc.
  if [ ! -f "${ZDRA_PLUGINS_FILE}" ] ; then
    echo "${PROGNAME:+$PROGNAME: }SKIP: No plugins file at '${ZDRA_PLUGINS_FILE}'." 1>&2
    exit
  fi
}


_hash_zdra_plugins_locally () {
  typeset failures=false
  typeset plugin plugin_root

  for plugin in `cat "${ZDRA_PLUGINS_FILE}"` ; do
    plugin_string="${plugin}"
    plugin_basename="${plugin_string##*/}"
    plugin_barename="${plugin_basename%.git}"

    for plugin_root in "$@" ; do
      echo
      echo "==> SIDRA Scripting Library plugin '${plugin_string}' hashing from local dir: '${plugin_root}'..."
      echo
      if ls -1 -d "${plugin_root}/${plugin_barename}" >/dev/null 2>&1 ; then
        cp -a -v "${plugin_root}/${plugin_barename}"/*.sh "$ZDRA_HOME/" 1>&2 || failures=true
        cp -a -v "${plugin_root}/${plugin_barename}"/*/ "$ZDRA_HOME/" 1>&2 || failures=true
        # Uniquely append:
        if ! grep -q -w "${plugin_barename}" "${ZDRA_PLUGINS_INSTALLED_FILE}" ; then
          echo "${plugin_barename}" >> "${ZDRA_PLUGINS_INSTALLED_FILE}"
        fi
        continue
      fi
    done
  done

  if ${failures:-false} ; then
    echo "${PROGNAME:+$PROGNAME: }WARN: some copy jobs failed." 1>&2
    return 1
  fi
}


_hash_zdra_plugins () {

  typeset failures=false

  if [ "$#" -gt 0 ] ; then
    _hash_zdra_plugins_locally "$@"
    return $?
  elif [ -d "${DEV:-${HOME}/workspace}/sidra" ] ; then
    _hash_zdra_plugins_locally "${DEV:-${HOME}/workspace}"
    return $?
  fi

  echo
  echo "==> SIDRA Scripting Library plugin hashing from '${ZDRA_PLUGINS_FILE}'..."
  echo
  zdraplugin.sh -f "${ZDRA_PLUGINS_FILE}" || failures=true

  if ${failures:-false} ; then
    echo "${PROGNAME:+$PROGNAME: }WARN: some copy jobs failed." 1>&2
    return 1
  fi
}


_main () {
  _set_global_defaults
  _skip_if_no_plugins_file
  _hash_zdra_plugins "$@" || exit $?
  echo "${PROGNAME:+$PROGNAME: }COMPLETE"
  exit 0
}


_main "$@"
