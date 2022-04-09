#!/usr/bin/env bash

# Project / License at https://github.com/stroparo/sidra

# Purpose: Plugin installer for this scripting library.

PROGNAME="zdraplugin.sh"

# #############################################################################
# Mandatory requirements

_load_zdra () {
  typeset ZDRA_CURRENT_HOME="${ZDRA_HOME:-$HOME/.zdra}"
  if ! . "${ZDRA_CURRENT_HOME}/zdra.sh" "${ZDRA_CURRENT_HOME}" >/dev/null 2>&1 ; then
    echo 1>&2
    echo "Scripting Library could not be loaded. Fix it and call this again." 1>&2
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

! which git >/dev/null && echo "${PROGNAME:+$PROGNAME: }FATAL: git not in path" 1>&2 && exit 1

# #############################################################################
# Globals

export WORKDIR="$HOME"

export PNAME="$(basename "$0")"

export USAGE="
NAME
  ${PNAME} - Installs Scripting Library plugins

SYNOPSIS
  ${PNAME} [domain/]user/repo [[d/]u/r [[d/]u/r ...]]
  -s option will make it SSH (git@domain:user/repo)

DESCRIPTION
  Clone the repository pointed to by the argument.
  If no domain given, github.com will be the default.
"

# #############################################################################
# Prep args

# Options:

export DOMAIN="github.com"
export FORCE=false
export QUIET=false
export USE_SSH=false
export VERBOSE=false

OPTIND=1
while getopts ':fhqsv' opt ; do
  case ${opt} in

    h) echo "${USAGE}" ; exit ;;

    f) export FORCE=true;;
    q) export QUIET=true;;
    s) export USE_SSH=true;;
    v) export VERBOSE=true;;

  esac
done
shift $((OPTIND - 1))

if [ $# -eq 0 ] ; then
  echo "$USAGE"
  exit 1
fi

# #############################################################################
# Functions


_check_core () {
  if ! touch "${ZDRA_PLUGINS_FILE}" ; then
    echo "${PROGNAME:+$PROGNAME: }FATAL: Could not touch '${ZDRA_PLUGINS_FILE}' file." 1>&2
    exit 1
  fi
  if ! touch "${ZDRA_PLUGINS_INSTALLED_FILE}" ; then
    echo "${PROGNAME:+$PROGNAME: }FATAL: Could not touch '${ZDRA_PLUGINS_INSTALLED_FILE}' file." 1>&2
    exit 1
  fi
}


_install_plugins () {

  typeset domain user repo remainder # for repo URLs
  typeset protocol
  typeset repo_dir
  typeset repo_url
  typeset skip

  for plugin in "$@" ; do

    protocol=$(echo "${plugin}" | grep -o "^.*://")
    protocol=${protocol%://}
    : ${protocol:=https}
    plugin_string="${plugin}"
    plugin_basename="${plugin_string##*/}"
    plugin_barename="${plugin_basename%.git}"
    plugin="${plugin#*://}"

    [ -z "${plugin}" ] && echo "${PROGNAME:+$PROGNAME: }WARN: empty arg ignored" && continue

    if ! grep -q -w "${plugin_barename}" "${ZDRA_PLUGINS_INSTALLED_FILE}" || ${FORCE:-false} ; then
      echo
      echo "${PROGNAME:+$PROGNAME: }INFO: plugin '${plugin_barename}' (${plugin}) installation..."
    else
      echo
      echo "${PROGNAME:+$PROGNAME: }SKIP: plugin '${plugin_barename}' already installed."
      continue
    fi

    IFS='/' read domain user repo remainder <<EOF
${plugin}
EOF

    if [ -z "$domain" ] ; then
      echo "${PROGNAME:+$PROGNAME: }FATAL: Must pass at least [user/]repo." 1>&2
      echo 1>&2
      echo "$USAGE" 1>&2
      exit 1
    elif [ -z "$user" ] ; then
      echo "${PROGNAME:+$PROGNAME: }WARN: No 'domain/{user}/' prefix, defaulting to 'github.com/stroparo/'..." 1>&2
      # Shift right and put in a default domain and user:
      repo=$domain
      user=stroparo
      domain=github.com
    elif [ -z "$repo" ] ; then
      echo "${PROGNAME:+$PROGNAME: }WARN: No domain, defaulting to 'github.com'..." 1>&2
      # Shift right and put in a default domain:
      repo=$user
      user=$domain
      domain=github.com
    fi

    # Support longer URLs (more than one dir after the user):
    if [ -n "$remainder" ] ; then
      repo="${repo}/${remainder}"
    fi

    repo_dir=$(basename "${repo%.git}")
    if ${USE_SSH:-false} ; then
      repo_url="git@$domain/$user/${repo%.git}.git"
    else
      repo_url="${protocol}://$domain/$user/${repo%.git}.git"
    fi

    echo "${PROGNAME:+$PROGNAME: }INFO: Cloning '${repo_url}'..."
    echo "${PROGNAME:+$PROGNAME: }INFO: PWD: '$PWD'"
    
    while ! (git clone --depth 1 "${repo_url}" \
              && rm -f -r "${repo_dir}/.git" \
              && cp -a "${repo_dir}"/* "${ZDRA_HOME}/" \
              && (grep -q "${plugin_basename}\$" "${ZDRA_PLUGINS_FILE}" \
                    || echo "${plugin_string}" >> "${ZDRA_PLUGINS_FILE}") \
              && (grep -q "${plugin_basename}\$" "${ZDRA_PLUGINS_INSTALLED_FILE}" \
                    || echo "${plugin_string}" >> "${ZDRA_PLUGINS_INSTALLED_FILE}") \
              && rm -f -r "${repo_dir}" \
              && echo \
              && echo "${PROGNAME:+$PROGNAME: }INFO: Plugin at '${repo_url}' installed successfully" \
              && echo)
    do
      echo "${PROGNAME:+$PROGNAME: }WARN: Plugin '${plugin}' installation failed." 1>&2
      echo "${PROGNAME:+$PROGNAME: }WARN: Will keep trying..." 1>&2
      rm -f -r "${repo}"
      sleep 10
    done

    # Safety for next iteration:
    unset domain user repo remainder
    unset protocol repo_dir repo_url
  done

}


_list_installed () {
  cat "${ZDRA_PLUGINS_INSTALLED_FILE}"
}


_arg_dispatcher () {
  case "$1" in
    list*) _list_installed; return ;;
  esac

  for arg in "$@" ; do
    if [ -f "${arg}" ] ; then
      for plugin_in_file in `cat "${arg}"` ; do
        _install_plugins "${plugin_in_file}"
      done
    else
      _install_plugins "${arg}"
    fi
  done
}


_main () {
  cd "$WORKDIR"
  if [ "${PWD%/}" != "${WORKDIR%/}" ] ; then
    echo "${PROGNAME:+$PROGNAME: }FATAL: Could not cd to '${WORKDIR%/}'." 1>&2
    exit 1
  fi

  _check_core
  _arg_dispatcher "$@"
  chmodscriptszdra
  if ${ERRORS:-false} ; then
    exit 1
  fi
  exit 0
}


_main "$@"
