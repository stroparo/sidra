#!/usr/bin/env bash

# Generate RSA ssh key

PROGNAME="sshkeygenrsa.sh"

# #############################################################################
# Main routines

sshkeygenrsa () {
  # Info: Generate id_rsa if none present for the current user.

  typeset comment="${1:-${USER}@$(hostname)}"
  typeset keydir
  typeset keypath="${2:-${HOME}/.ssh/id_rsa}"
  typeset usage="Usage: {comment} [keypath=~/.ssh/id_rsa]"

  while [[ $- = *i* ]] && [ -z "${comment}" ] ; do
    echo 'SSH key comment (email, name or whatever)'
    read comment
  done

  while [[ $- = *i* ]] && [ -e "${keypath}" ] ; do
    echo "Key '${keypath}' already exists, type another path"
    read keypath
  done
  # Non interactive, might still exist...
  if [ -e "${keypath}" ] ; then
    echo "${PROGNAME:+$PROGNAME: }SKIP: Key '${keypath}' already exists" 1>&2
    echo "${usage}" 1>&2
    exit
  fi

  keydir="$(dirname "${keypath}")"

  if [ ! -d "${keydir}" ] ; then

    mkdir "${keydir}"

    if [ ! -d "${keydir}" ] ; then
      echo "FATAL: Could not create dir '${keydir}'." 1>&2
      return 1
    fi
  fi

  ssh-keygen -t rsa -b 4096 -C "${comment:-mykey}" -f "${keypath}" \
    && chmod 700 "${keypath}" \
    && echo \
    && echo "==> '${keypath}' file:" \
    && ls -l "${keypath}" \
    && echo \
    && echo "==> '${keypath}' contents:" \
    && cat "${keypath}.pub"
}

sshsetfiles () {

  typeset keyfile="$1"

  chmod 700 "$HOME/.ssh"
  [ -e "$HOME"/.ssh/authorized_keys ] && chmod 600 "$HOME"/.ssh/authorized_keys
  chmod 600 "$HOME"/.ssh/id*

  if [ -f "${keyfile}" ] ; then
    chmod 600 "${keyfile}"
  fi
}

# #############################################################################
# Main program

echo "################################################################################"
echo sshkeygenrsa

sshkeygenrsa "$@" || exit $?
sshsetfiles "$2"
