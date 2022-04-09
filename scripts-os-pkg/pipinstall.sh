#!/usr/bin/env bash

# Globals

PROGNAME="pipinstall.sh"
USAGE="$PROGNAME [-v venv] [pip package|file containing a list of pip packages]+

REMARK
If -e venv option, then use pyenv to activate it (fail on pyenv abscence)
"

# #############################################################################
# Routines

_pyenv_load () {
  echo "${PROGNAME:+$PROGNAME: }INFO: Loading pyenv and virtualenvwrapper..."
  export PATH="${PYENV_ROOT:-$HOME/.pyenv}/bin:${PATH}"
  if command -v pyenv >/dev/null 2>&1 ; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    eval "$(grep 'VIRTUALENVWRAPPER_PYTHON=' ~/.bashrc)"
    eval "$(grep '^source.*virtualenvwrapper.sh$' ~/.bashrc)"
  fi
}


pipinstall () {
  typeset venv
  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':hv:' option ; do
    case "${option}" in
      h)
        echo "$USAGE"
        exit
        ;;
      v)
        venv="${OPTARG}"
        if ! which pyenv >/dev/null 2>&1 ; then
          echo "${PROGNAME:+$PROGNAME: }FATAL: a virtualenv was specified but no pyenv is available to activate it." 1>&2
          return 1
        fi
        ;;
    esac
  done
  shift $((OPTIND-1)) ; OPTIND="${oldind}"

  _pyenv_load
  python -m pip --version > /dev/null || return $?

  if [ -n "${venv}" ] ; then
    : ${WORKON_HOME:=${HOME}/.ve} ; export WORKON_HOME
    : ${PROJECT_HOME:=${HOME}/workspace} ; export PROJECT_HOME

    if ! pyenv activate "${venv}" ; then
      echo "${PROGNAME:+$PROGNAME: }FATAL: Could not switch to the '${venv}' virtualenv." 1>&2
      return 1
    fi
  elif ! pyenv global >/dev/null 2>&1 ; then
    echo "${PROGNAME:+$PROGNAME: }FATAL: No pyenv global set." 1>&2
    return 1
  fi

  for pkg in "$@" ; do
    if [ -f "${pkg}" ] ; then
      for readpkg in $(cat "${pkg}") ; do
        echo ${BASH_VERSION:+-e} "\n==> python -m pip install '$readpkg'..."
        python -m pip install "$readpkg"
      done
    else
      echo ${BASH_VERSION:+-e} "\n==> python -m pip install '${pkg}'..."
      python -m pip install "${pkg}"
    fi
  done
}

# #############################################################################
# Main

pipinstall "$@" || exit "$?"
