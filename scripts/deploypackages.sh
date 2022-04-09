#!/usr/bin/env bash

# Globals

USAGE="deploypackages - Deploy packages from-to the given directories.

$(basename "$0") [-c] [-x {exclude-expression}] {packages-path} {destination}

Options:
-c  Asks for prior user confirmation.
"

# #############################################################################
# Prep dependencies

if ! . "${ZDRA_HOME}/zdra.sh" "${ZDRA_HOME}" >/dev/null 2>&1 || [ -z "${ZDRA_LOADED}" ] ; then
  echo "$(basename "$0"): FATAL: Could not load SIDRA Scripting Library." 1>&2
  exit 1
fi

# #############################################################################
# Functions

deploypackages () {

  typeset deploypath
  typeset exclude
  typeset files
  typeset pkgspath
  typeset userconfirm=false

  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':chx:' opt ; do
    case "${opt}" in
      c) userconfirm=true ;;
      h) echo "$USAGE" ; exit ;;
      x) exclude="${OPTARG}" ;;
    esac
  done
  shift $((OPTIND - 1)) ; OPTIND="${oldind}"

  pkgspath="$(cd "${1}" || exit 1 ; echo "$PWD")" || exit 1
  deploypath="$(cd "${2}" || exit 1 ; echo "$PWD")" || exit 1

  ! (ls -1 "${pkgspath}" | egrep '([.]7z|[.]zip|bz2|gz)$') && return
  $userconfirm && ! userconfirm "Deploy packages from '${pkgspath}' ?" && return

  echo "INFO: Packages path '${pkgspath}' .." 1>&2
  echo "INFO: .. deploying to '${deploypath}' .." 1>&2

  files=$(ls -1 \
    "${pkgspath}"/*.7z \
    "${pkgspath}"/*.zip \
    "${pkgspath}"/*bz2 \
    "${pkgspath}"/*gz \
    2>/dev/null)
  [ -n "$exclude" ] && files=$(echo "$files" | egrep -v "$exclude")

  unarchive -v -o "${deploypath}" ${files}
}

# #############################################################################
# Main

deploypackages "$@"
exit "$?"
