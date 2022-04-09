#!/usr/bin/env bash

# Scripting Library setup / installation routine

PROGNAME="setup.sh"

# #############################################################################
# Fixed globals

USAGE="[-f] [-h]"

ZDRA_PKG_URL="https://bitbucket.org/stroparo/sidra/get/master.zip"
ZDRA_PKG_URL_ALT="https://github.com/stroparo/sidra/archive/master.zip"
TEMP_DIR=$HOME

# #############################################################################
# Options

OPTIND=1
while getopts ':fh' option ; do
  case "${option}" in
    f)
      FORCE=true
      IGNORE_SSL=true
      ;;
    h)
      echo "${USAGE}"
      exit
      ;;
  esac
done
shift "$((OPTIND-1))"

# #############################################################################
# Dynamic globals

# Default INSTALL_DIR to not evaluate some variable if passed
# in the directory, so it goes in the "load code" variable
# which will be appended to the shell profiles as is:
ZDRA_INSTALL_DIR="$(echo "${1:-\${HOME\}/.zdra}" | tr -s /)"
ZDRA_LOAD_CODE="[ -r \"${ZDRA_INSTALL_DIR}/zdra.sh\" ] && source \"${ZDRA_INSTALL_DIR}/zdra.sh\" \"${ZDRA_INSTALL_DIR}\" 1>&2"

# After having that "load code" for shell profiles,
#   finally eval the installation dir to proceed:
ZDRA_INSTALL_DIR="$(eval echo "\"${ZDRA_INSTALL_DIR}\"")"

BACKUP_FILENAME="${ZDRA_INSTALL_DIR}-$(date '+%y%m%d-%OH%OM%OS')"

# Setup the downloader program (curl/wget)
_no_download_program () {
  echo "${PROGNAME} (SIDRA): FATAL: curl and wget missing" 1>&2
  exit 1
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
# Checks

# Skip this setup altogether if installation path already occupied:
if [ -d "$ZDRA_INSTALL_DIR" ] ; then
  echo "${PROGNAME} (SIDRA): SKIP: '${ZDRA_INSTALL_DIR}' dir already exists" 1>&2
  exit
fi

# #############################################################################
# Install

if [ -e ./zdra.sh ] && [ "${PWD}" != "${ZDRA_INSTALL_DIR}" ] ; then
  echo "SIDRA Scripting Library setup from local dir '${PWD}'..." 1>&2
  mkdir "${ZDRA_INSTALL_DIR}" \
    && cp -f -R -v "${PWD}"/* "${ZDRA_INSTALL_DIR}"/
  INST_RESULT=$?
  echo "${PROGNAME} (SIDRA): INFO: SIDRA Scripting Library setup dir used was '${PWD}'"
else
  echo "SIDRA Scripting Library setup: downloading and installing..." 1>&2
  ("${DLPROG}" ${DLOPT} ${DLOPTEXTRA} ${DLOUT} "${ZDRA_INSTALL_DIR}.zip" "${ZDRA_PKG_URL}" \
    || "${DLPROG}" ${DLOPT} ${DLOPTEXTRA} ${DLOUT} "${ZDRA_INSTALL_DIR}.zip" "${ZDRA_PKG_URL_ALT}") \
    && unzip "${ZDRA_INSTALL_DIR}.zip" -d "$TEMP_DIR"

  # Old: mv "${TEMP_DIR}/sidra-master" "${ZDRA_INSTALL_DIR}"
  DL_RESULT=$?
  if [ $DL_RESULT -eq 0 ] ; then
    zip_dir=$(unzip -l "${ZDRA_INSTALL_DIR}.zip" | head -5 | tail -1 | awk '{print $NF;}')
    echo "Zip dir: '${zip_dir}'" 1>&2
    mv -f -v "$TEMP_DIR"/"${zip_dir}" "${ZDRA_INSTALL_DIR}" 1>&2
    INST_RESULT=$?
  else
    INST_RESULT=${DL_RESULT}
  fi
fi

# #############################################################################
# Verification

if [ ${INST_RESULT} -ne 0 ] ; then
  echo "${PROGNAME} (SIDRA): FATAL: installation error." 1>&2
  rm -f -r "${ZDRA_INSTALL_DIR}"
  exit ${INST_RESULT}
fi

# #############################################################################
# Cleanup installed plugins list file

# At this point this fresh installation succeeded, so this
#   guarantees there are no status files from previous
#   installations:
eval $(grep ZDRA_PLUGINS_INSTALLED_FILE= "${ZDRA_INSTALL_DIR}/zdra.sh")
echo "${PROGNAME} (SIDRA): INFO: Plugins installed file: '${ZDRA_PLUGINS_INSTALLED_FILE}'"
rm -f -v "${ZDRA_PLUGINS_INSTALLED_FILE}" 2>/dev/null

# #############################################################################
echo "${PROGNAME} (SIDRA): INFO: Loading SIDRA Scripting Library..."

. "${ZDRA_INSTALL_DIR}/zdra.sh" "${ZDRA_INSTALL_DIR}"

if [ -n "${ZDRA_LOADED}" ] ; then
  echo "${PROGNAME} (SIDRA): INFO: Setting shell profiles up..."
  touch "${HOME}/.bashrc" "${HOME}/.zshrc"
  # About greps below,
  #   omitting the path in the pattern (/zdra.sh) is on purpose since
  #   SIDRA could have been installed with a non evaluated variable
  #   in the profiles earlier, and a reinstallation client code
  #   calling this might have passed in an actual path, which
  #   would cause appendunique to not be unique anymore thus
  #   putting in another ie duplicate SIDRA loading code:
  if ! grep -q "/zdra.sh" "${HOME}/.bashrc" ; then
    appendunique -n "${ZDRA_LOAD_CODE}" "${HOME}/.bashrc"
  fi
  if ! grep -q "/zdra.sh" "${HOME}/.zshrc" ; then
    appendunique -n "${ZDRA_LOAD_CODE}" "${HOME}/.zshrc"
  fi

  echo "${PROGNAME} (SIDRA): INFO: Hashing plugins..."
  zdrahashplugins.sh

  echo "${PROGNAME} (SIDRA): INFO: Hashing script modes..."
  chmodscriptszdra -v

  echo "${PROGNAME} (SIDRA): INFO: SIDRA installed." 1>&2

  exit 0
else
  echo "${PROGNAME} (SIDRA): FATAL: SIDRA installed but could not load it." 1>&2

  exit 99
fi

# #############################################################################
