# Scripting Development and Runtime Library

# Project / License at https://github.com/stroparo/sidra

# #############################################################################
# Globals

# Main project global 'ZDRA_HOME':
ZDRA_HOME="${1:-${HOME%/}/.zdra}"
# Squeeze slashes
if which tr >/dev/null 2>&1 ; then
  ZDRA_HOME="$(echo "$ZDRA_HOME" | tr -s /)"
fi
export ZDRA_HOME

export ZDRA_BACKUPS_DIR="${HOME}/.zdra-backups"
export ZDRA_CONF="${ZDRA_HOME}/conf"
export ZDRA_PLUGINS_FILE="${HOME}/.zdraplugins"
export ZDRA_PLUGINS_INSTALLED_FILE="${HOME}/.zdraplugins-installed"
export ZDRA_VERSION='v0.4.0 2018-01-05'

# #############################################################################
# SIDRA core

touch "${ZDRA_PLUGINS_FILE}"
touch "${ZDRA_PLUGINS_INSTALLED_FILE}"
. "${ZDRA_HOME}/zdra00.sh" || return 100
sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/zdra0[1-9]*sh"

# #############################################################################
# Functions

if [[ $ZDRA_VERBOSE = vv ]] ; then
  SOURCE_FUNCTIONS_OPTIONS="-v"
fi

if [ -n "${ZDRA_SOURCES_FUNCTIONS}" ] ; then
  for functions_file in $(echo ${ZDRA_SOURCES_FUNCTIONS}) ; do
    sourcefiles ${SOURCE_FUNCTIONS_OPTIONS} "${ZDRA_HOME}/functions/${functions_file%.sh}.sh"
  done
else
  sourcefiles -t ${SOURCE_FUNCTIONS_OPTIONS} "${ZDRA_HOME}/functions/*sh"
fi


# #############################################################################
# SIDRA additional core sources

sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/zdra[1-8][0-9]*sh"
sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/zdra[A-Za-z]*sh"
sourcefiles -v "${ZDRA_HOME}/sshagent.sh"

# #############################################################################
# Environments

if [ -n "${ZDRA_SOURCES_ENVIRONMENTS}" ] ; then
  for env in $(echo ${ZDRA_SOURCES_ENVIRONMENTS}) ; do
    env="${env#env}"
    sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/env${env%.sh}.sh"
  done
else
  sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/env*sh"
fi

# #############################################################################
# Post SIDRA loading calls

sourcefiles ${ZDRA_VERBOSE:+-v} -t "${ZDRA_HOME}/zdra99post.sh"

# #############################################################################
