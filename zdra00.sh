# Project / License at https://github.com/stroparo/sidra

# Globals

ZDRA_SETUP_URL="https://bitbucket.org/stroparo/sidra/raw/master/setup.sh"
ZDRA_SETUP_URL_ALT="https://raw.githubusercontent.com/stroparo/sidra/master/setup.sh"

# #############################################################################
# Globals - Mounts prefix root dir filename for Linux and Windows:

if (uname -a | grep -i -q linux) ; then
  MOUNTS_PREFIX="/mnt"
  MOUNTS_PREFIX_EXTERNAL="/media/$USER"
  if egrep -i -q -r 'centos|fedora|oracle|red *hat' /etc/*release ; then
    MOUNTS_PREFIX_EXTERNAL="/var/media/$USER"
  fi
elif (uname -a | egrep -i -q "cygwin|mingw|msys|win32|windows") ; then
  if [ -d '/c/Windows' ] ; then
    MOUNTS_PREFIX=""
  elif [ -d '/drives/c/Windows' ] ; then
    MOUNTS_PREFIX="/drives"
  elif [ -d '/cygdrive/c/Windows' ] ; then
    MOUNTS_PREFIX="/cygdrive"
  fi
fi

# #############################################################################
# Globals - the downloader program (curl/wget)

# Setup the downloader program (curl/wget)
_no_download_program () {
  echo "${PROGNAME} (SIDRA): FATAL: curl and wget missing" 1>&2
  return 1
}
export DLOPTEXTRA
if which curl >/dev/null 2>&1 ; then
  export DLPROG=curl
  export DLOPT='-LSfs'
  export DLOUT='-o'
  if ${IGNORE_SSL:-false} ; then
    export DLOPT="-k ${DLOPT}"
  fi
elif which wget >/dev/null 2>&1 ; then
  export DLPROG=wget
  export DLOPT=''
  export DLOUT='-O'
else
  export DLPROG=_no_download_program
fi

# #############################################################################
# Globals - the encryption program (truecrypt/veracrypt)

export CRYPTPROG=truecrypt
if ! which "${CRYPTPROG}" >/dev/null 2>&1 && which veracrypt >/dev/null 2>&1 ; then
  export CRYPTPROG=veracrypt
fi

# #############################################################################
# Core functions


# Oneliners
zdrah () { zdrahash -r ; }
zdraversion () { echo "==> SIDRA Scripting Library - ${ZDRA_VERSION}" ; }


zdrabackup () {
  typeset zdrahome="${1:-${ZDRA_HOME:-${HOME}/.zdra}}"
  typeset timestamp="$(date +%Y%m%d-%OH%OM%OS)"
  typeset bakdir="${ZDRA_BACKUPS_DIR}/${timestamp}"

  [ -d "${bakdir}" ] || mkdir -p "${bakdir}"
  ls -d "${bakdir}" >/dev/null || return $?

  export ZDRA_LAST_BACKUP=""
  if ! ls -1 -d "${zdrahome}"/* >/dev/null 2>&1 ; then
    return 0
  fi
  cp -a "${zdrahome}"/* "${bakdir}"/
  if [ $? -eq 0 ] ; then
    export ZDRA_LAST_BACKUP="$(ls -1 -d "${bakdir}")"
    echo "ZDRA_LAST_BACKUP=${ZDRA_LAST_BACKUP}"
    return 0
  else
    return 1
  fi
}


zdrarestorebackup () {
  typeset progname="zdrarestorebackup"
  ZDRA_LAST_BACKUP="${ZDRA_LAST_BACKUP:-${ZDRA_BACKUPS_DIR}/${1##$ZDRA_BACKUPS_DIR/}}"

  if [ -z "${ZDRA_LAST_BACKUP}" ] ; then
    echo "${progname}: SKIP: No last backup in the current session." 1>&2
    return 1
  fi

  if [ -d "${ZDRA_LAST_BACKUP}" ] ; then
    echo "${progname}: INFO: Restoring SIDRA Scripting Library backup at '${ZDRA_LAST_BACKUP}'..." 1>&2
    rm -f -r "${ZDRA_HOME}";  mkdir "${ZDRA_HOME}"
    if [ -d "${ZDRA_HOME}" ] \
      && [ ! -f "${ZDRA_HOME}/zdra.sh" ] \
      && cp -a -v "${ZDRA_LAST_BACKUP}/"* "${ZDRA_HOME}/"
    then
      echo "${progname}: INFO: Backup restored" 1>&2
      return 0
    else
      echo "${progname}: FATAL: Restore failed" 1>&2
      return 1
    fi
  else
    echo "${progname}: FATAL: There was no previous SIDRA version backed up" 1>&2
    return 1
  fi
}


zdrahash () {
  # Purpose: rehashing of this scripting library and plugins from local source codebases.
  # Syntax: [-r] [this-lib-sources-dir:${DEV}/sidra]
  #   -r will reload SIDRA Scripting Library in the current shell session

  typeset errors
  typeset progname="zdrahash()"

  # Simple option parsing must come first:
  typeset loadcmd=:
  [ "$1" = '-r' ] && loadcmd="echo \"${progname}: INFO: SIDRA loading...\" ; zdraload" && shift

  typeset zdrahome="${ZDRA_HOME:-${HOME}/.zdra}"
  typeset zdrasrc="${1:-${DEV}/sidra}"
  typeset errors=false

  # Requirements
  if [ ! -f "${zdrasrc}/zdra.sh" ] ; then
    echo "${progname}: FATAL: No SIDRA Scripting Library sources found in '${zdrasrc}'." 1>&2
    return 1
  fi
  if ! zdrabackup ; then
    echo "${progname}: FATAL: error in zdrabackup." 1>&2
    return 1
  fi
  if [ -d "${zdrahome}" ] && ! rm -f -r "${zdrahome}" ; then
    echo "${progname}: FATAL: Could not remove pre-existing directory '${zdrahome}'." 1>&2
    return 1
  fi

  echo
  echo "${progname}: INFO: ==> SIDRA Scripting Library rehash started..."
  set -x
  if ! : > "${ZDRA_PLUGINS_INSTALLED_FILE:-/dev/null}" \
    || ! mkdir -p "${zdrahome}" \
    || ! (cd "${zdrasrc}" && [ "$PWD" = "${zdrasrc}" ] && ./setup.sh "${zdrahome}"/)
  then
    errors=true
  fi
  set +x

  if ! ${errors:-false} ; then
    echo
    echo "${progname}: INFO: ==> SIDRA Scripting Library rehash complete"

    zdraload "${zdrahome}"

    echo "${progname}: INFO: Hashing plugins..."
    sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/zdra10path.sh"
    zdrahashplugins.sh
    sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/zdra10path.sh"

    echo "${progname}: INFO: Hashing script modes..."
    chmodscriptszdra -v

    eval "$loadcmd"
  else
    echo "${progname}: ERROR: SIDRA Scripting Library rehashing failed." 1>&2
    zdrarestorebackup
  fi
}


zdraupgrade () {

  typeset progname="zdraupgrade"

  if [ -z "${ZDRA_HOME}" ] ; then
    echo "${progname}: FATAL: No ZDRA_HOME set." 1>&2
    return 1
  fi
  if [ ! -d "${ZDRA_HOME}" ] ; then
    echo "${progname}: FATAL: No ZDRA_HOME='${ZDRA_HOME}' dir." 1>&2
    return 1
  fi

  if ! zdrabackup ; then
    echo "${progname}: FATAL: error in zdrabackup." 1>&2
    return 1
  elif (
    rm -rf "${ZDRA_HOME}" \
    && zdraload "${ZDRA_HOME}"
  )
  then
    echo "${progname}: SUCCESS: upgrade complete."
    echo "${progname}: INFO: backup at '${ZDRA_LAST_BACKUP}'."
    zdraload "${ZDRA_HOME}"
  else
    echo "${progname}: FATAL: upgrade failed." 1>&2
    zdrarestorebackup
  fi
}


# #############################################################################
# Functions


# Function d - Dir navigation
unalias d 2>/dev/null
unset d 2>/dev/null
d () {
  if [ -e "$1" ] ; then cd "$1" ; shift ; fi
  for dir in "$@" ; do
    if [ -e "$dir" ] ; then cd "$dir" ; continue ; fi
    found=$(ls -1d *"${dir}"*/ | head -1)
    if [ -z "$found" ] ; then found="$(find . -type d -name "*${dir}*" | head -1)" ; fi
    if [ -n "$found" ] ; then echo "$found" ; cd "$found" ; fi
  done
  pwd; which exa >/dev/null 2>&1 && exa -ahil || ls -al
  if [ -e ./.git ] ; then
    echo ; git branch -vv
    echo ; git status -s
  fi
}


zdralistfunctions () {

  typeset filename item items itemslength

  for i in $(ls -1 "${ZDRA_HOME}"/functions/*sh) ; do

    items=$(egrep '^ *(function [_a-zA-Z0-9][_a-zA-Z0-9]* *[{]|[_a-zA-Z0-9][_a-zA-Z0-9]* *[(][)] *[{])' "$i" /dev/null | \
          sed -e 's#^.*functions/##' -e  's/[(][)].*$//')
    filename=$(echo "$items" | head -n 1 | cut -d: -f1)
    items=$(echo "$items" | cut -d: -f2)
    itemslength=$(echo "$items" | wc -l | awk '{print $1;}')

    if [ -n "$items" ] ; then
      for item in $(echo "$items" | cut -d: -f2) ; do
        echo "$item in $filename"
      done
    fi
  done | sort
}


_zdragetscriptsdirs () {
  bash -c "ls -1 -d '${ZDRA_HOME}/installers'*" 2>/dev/null
  bash -c "ls -1 -d '${ZDRA_HOME}/recipes'*" 2>/dev/null
  bash -c "ls -1 -d '${ZDRA_HOME}/scripts'*" 2>/dev/null
}
zdralistscripts () {
  find $(_zdragetscriptsdirs) -type f
}


zdrahelp () {
  echo "SIDRA Scripting Library - Help

d - handy dir navigation function
zdrahelp - display this help messsage
zdrainfo - display environment information
zdralistfunctions - list SIDRA Scripting Library's functions
zdralistscripts - list SIDRA Scripting Library's scripts
zdraversion - display the version of this SIDRA Scripting Library instance
" 1>&2
}


zdrainfo () {
  zdraversion 1>&2
  echo "ZDRA_HOME='${ZDRA_HOME}'" 1>&2
}


zdraload () {
  typeset progname="zdraload"

  # Info: loads SIDRA. If it does not exist, download and install to the default path.
  # Syn: [zdra_home=~/.zdra]

  typeset zdra_install_dir="$(echo "${1:-${ZDRA_HOME:-\${HOME\}/.zdra}}" | tr -s /)"
  typeset zdra_home="$(eval echo "\"${zdra_install_dir}\"")"

  if [ -f "${zdra_home}/zdra.sh" ] ; then
    . "${zdra_home}/zdra.sh" "$zdra_home"
    return $?
  fi

  export ZDRA_HOME="${zdra_home}"
  echo
  echo "${progname}: INFO: Installing SIDRA into '${zdra_install_dir}' ('${ZDRA_HOME}') ..." 1>&2
  unset ZDRA_LOADED
  bash -c "$(cat "${DEV}/sidra/setup.sh" 2>/dev/null \
    || ${DLPROG} ${DLOPT} ${DLOPTEXTRA} ${DLOUT} - "${ZDRA_SETUP_URL}" \
    || ${DLPROG} ${DLOPT} ${DLOPTEXTRA} ${DLOUT} - "${ZDRA_SETUP_URL_ALT}")" \
    setup.sh "${zdra_install_dir}"
  if ! . "${ZDRA_HOME}/zdra.sh" "${ZDRA_HOME}" 1>&2 || [ -z "${ZDRA_LOADED}" ] ; then
    echo "${progname}: FATAL: Could not load SIDRA Scripting Library." 1>&2
    return 1
  else
    return 0
  fi
}


sourcefiles () {
  # Info: Each arg is a glob; source all glob expanded paths.
  #  Tilde paths are accepted, as the expansion is yielded
  #  via eval. Expanded directories are ignored.
  #  Stdout is fully redirected to stderr.

  typeset pname='sourcefiles'
  typeset quiet=false
  typeset tolerant=false
  typeset verbose=false

  typeset name src srcs srcresult
  typeset nta='Non-tolerant abort.'

  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':n:qtv' opt ; do
    case "${opt}" in
      n) name="${OPTARG}";;
      q) quiet=true;;
      t) tolerant=true;;
      v) verbose=true;;
    esac
  done
  shift $((OPTIND - 1)) ; OPTIND="${oldind}"

  if test -n "${name}" && $verbose && ! $quiet ; then
    echo "==> Sourcing group '${name}'" 1>&2
  fi

  for globpattern in "$@" ; do

    srcs="$(eval command ls -1d ${globpattern} 2>/dev/null)"

    if [ -z "$srcs" ] ; then
      if ! ${tolerant} ; then
        $quiet || echo "FATAL: ${nta} Bad glob." 1>&2
        return 1
      fi
      continue
    fi

    exec 4<&0

    while read src ; do

      $verbose && ! $quiet && echo "==> Sourcing '${src}' ..." 1>&2

      if [ -r "${src}" ] ; then
        . "${src}" 1>&2
      else
        $quiet || echo "$warn '${src}' is not readable." 1>&2
        false
      fi
      srcresult=$?

      if [ "${srcresult}" -ne 0 ] ; then
        if ! $tolerant ; then
          $quiet || echo "FATAL: ${nta} While sourcing '${src}'." 1>&2
          return 1
        fi

        $quiet || echo "WARN: Tolerant fail for '${src}'." 1>&2
      # else
      #     if $verbose && ! $quiet ; then
      #         echo "INFO: => '${src}' completed successfully." 1>&2
      #     fi
      fi
    done <<EOF
${srcs}
EOF
  done
  if $verbose && test -n "${name}" ; then
    echo "INFO: group '${name}' sourcing complete." 1>&2
  fi
}
