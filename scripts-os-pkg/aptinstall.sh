#!/usr/bin/env bash

# Install APT packages

# #############################################################################
# Globals

PROGNAME="$(basename "${0:-aptinstall.sh}")"
USAGE="[-r PPA_REPO] packages"

# System installers
export APTPROG=apt-get; which apt >/dev/null 2>&1 && export APTPROG=apt
export INSTPROG="$APTPROG"

unset PPA_REPO

# #############################################################################
# Check prereqs

if ! egrep -i -q -r 'debian|ubuntu' /etc/*release ; then
  echo "$PROGNAME: FATAL: only Debian/Ubuntu distributions are supported." 1>&2
  exit 1
fi

# #############################################################################
# Dynamic globals

# Options:
OPTIND=1
while getopts ':hr:' option ; do
  case "${option}" in
    h) echo "$USAGE"; exit;;
    r) PPA_REPO="${OPTARG}";;
  esac
done
shift "$((OPTIND-1))"

# #############################################################################
# Helpers

_add_ppa_repo () {

  typeset ppa="$1"
  if [ -z "$ppa" ] ; then return ; fi

  echo ${BASH_VERSION:+-e} "\n==> ls /etc/apt/sources.list.d/${ppa%/*}*.list"

  if ! eval ls -l "/etc/apt/sources.list.d/${ppa%/*}*.list" 2>/dev/null ; then
    sudo add-apt-repository -y "ppa:$ppa"
    sudo apt-get update
  fi
}

_install_packages () {
  for package in "$@" ; do
    if dpkg -s "${package}" ; then
      echo "${PROGNAME:+$PROGNAME: }SKIP: Package '${package}' already installed." 1>&2
      continue
    fi

    echo "Installing '$package'..."
    if ! sudo $INSTPROG install -y "$package" >/tmp/pkg-install-${package}.log 2>&1 ; then
      echo "${PROGNAME:+$PROGNAME: }WARN: There was an error installing package '$package' - see '/tmp/pkg-install-${package}.log'." 1>&2
    fi
  done
}

# #############################################################################
# Main

if [ -n "$PPA_REPO" ] ; then
  _add_ppa_repo "$PPA_REPO"
fi
sudo "$INSTPROG" update
_install_packages "$@"
