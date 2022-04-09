# Post env profile - execute after all other env/profiles have been loaded
# Execute code in the ZDRA_POST_CALLS global environment variable.

ZDRA_LOADED=true

# Logging path:
: ${ZDRA_ENV_LOG:=$HOME/log} ; export ZDRA_ENV_LOG
if [ ! -d "${ZDRA_ENV_LOG}" ] ; then
  mkdir -p "${ZDRA_ENV_LOG}" 2>/dev/null
fi

# Post-calls
# Evaluate each line in the ZDRA_POST_CALLS variable:

if [ -n "${ZDRA_POST_CALLS}" ] ; then
  ZDRA_POST_STATUS=0

  while read acommand ; do

    if [ -n "${ZDRA_VERBOSE}" ] ; then
      echo ${BASH_VERSION:+-e} "==> Next command in ZDRA_POST_CALLS: \c" 1>&2
      echo "${acommand}" 1>&2
    fi

    if ! eval "${acommand}" ; then
      ZDRA_POST_STATUS=1
      echo "ERROR: Command '${acommand}'" 1>&2
    fi

  done <<EOF
${ZDRA_POST_CALLS:-:}
EOF
fi

# Display SIDRA Information:
if [ -n "${ZDRA_VERBOSE}" ] ; then
  echo 1>&2
  zdrainfo 1>&2
fi

return ${ZDRA_POST_STATUS:-0}
