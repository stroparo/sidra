#!/usr/bin/env bash

# Project / License at https://github.com/stroparo/sidra

export PNAME="$(basename "$0")"
export USAGE="
NAME
    ${PNAME} - exec git for all descending gits from current directory

SYNOPSIS
    ${PNAME}
    ${PNAME} -h
    ${PNAME} [-c newCommandInsteadOfGit] [-v] [command args]
    ${PNAME} -p option causes commands to be executed concurrently

DESCRIPTION

Remark:
    GGIGNORE global can have an egrep regex for git repos to be ignored.

Rmk #2:
    -v shows command even if its output is empty (pull|push not up to date).
"

# #############################################################################
# Globals

# #############################################################################
# Prep args

# Options:

export FULL=false
export PROGRAM='git'

export VERBOSE=false
: ${GITR_VERBOSE_OPTION:=false} ; export GITR_VERBOSE_OPTION ; ${GITR_VERBOSE_OPTION} && export VERBOSE=true

export PARALLEL=false
: ${GITR_PARALLEL:=false} ; export GITR_PARALLEL
if ${GITR_PARALLEL} ; then export PARALLEL=true; fi

OPTIND=1
while getopts ':c:fhpv' opt ; do
    case "${opt}" in
    c) export PROGRAM="${OPTARG}";;
    f) export FULL=true;;
    h) echo "$USAGE" ; exit ;;
    p) export PARALLEL=true;;
    v) export VERBOSE=true;;
    esac
done
shift $((OPTIND-1))

# #############################################################################
# Prep

export GITCMD="$1"
shift

if [ "$GITCMD" = pull ] || [ "$GITCMD" = merge ] ; then
  export PARALLEL=false
fi

export GITREPOS="$(
if [ -z "$GGIGNORE" ] || ${FULL:-false} ; then
    find . -type d -name ".git"
else
    find . -type d -name ".git" | egrep -i -v "${GGIGNORE}/[.]git"
fi
)"

# #############################################################################
# Functions

prep () {

    typeset oldpwd="$PWD"

    if ! . "${ZDRA_HOME}/zdra.sh" "${ZDRA_HOME}" >/dev/null 2>&1 || [ -z "${ZDRA_LOADED}" ] ; then
        echo "${PNAME}: FATAL: Could not load SIDRA Scripting Library." 1>&2
        echo "ZDRA_HOME='${ZDRA_HOME}'" 1>&2
        exit 1
    fi

    cd "$oldpwd"
}

cmdexpand () {
    if echogrep -q '^g?ss$' "$GITCMD" ; then export GITCMD='status -s'
    elif echogrep -q '^g?st$' "$GITCMD" ; then export GITCMD='status'
    elif echogrep -q '^g?l$' "$GITCMD" ; then export GITCMD='pull'
    elif echogrep -q '^g?p$' "$GITCMD" ; then export GITCMD='push'
    fi
}

setGITRCMD () {
    export GITRCMD="$(cat <<EOF
set -e

cd {}/..

export HEADERMSG="\$(echo "${PROGRAM:-git}" "${GITCMD}" $@ "# At '\${PWD}'")"
export CMDOUT="\$(eval "${PROGRAM:-git}" "${GITCMD}" $@ 2>&1)"

if ([ "${GITCMD}" != 'status' ] && [ -z "\$CMDOUT" ]) || \
    ([ "${GITCMD}" = 'pull' ] && (echo "\$CMDOUT" | grep -i -q 'Already up.to.date')) || \
    ([ "${GITCMD}" = 'push' ] && (echo "\$CMDOUT" | grep -i -q 'Everything up.to.date'))
then
    hasoutput=false
else
    hasoutput=true
fi

if ${VERBOSE:-false} || \${hasoutput:-false} ; then
    echo "==> \${HEADERMSG}"
    echo "\${CMDOUT}"
    echo ''
fi
EOF
)"

# echo "GITRCMD=$GITRCMD" # DEBUG
}

execCalls () {
    typeset reponame

    for repo in ${GITREPOS}; do
        reponame=${repo%.git}
        reponame=${repo##*/}
        (cd $repo/.. && \
            echo "==> ${PROGRAM:-git} ${GITCMD} $@ # At '${PWD}'" 1>&2 && \
            eval "${PROGRAM:-git}" "${GITCMD}" "$@" \
            2>&1 | tee "$ZDRA_ENV_LOG/${PROGRAM:-git}_$(date '+%Y%m%d_%OH%OM%OS')_${reponame}.log")
        if ${VERBOSE:-false} ; then
            echo '---'
        fi
    done
}

execCallsParallel () {
    (paralleljobs.sh -p 32 -q -t -z "$PROGRAM" "$GITRCMD" <<EOF
${GITREPOS}
EOF
)
}

gitr () {
    cmdexpand
    if ${PARALLEL} ; then
        setGITRCMD "$@"
        execCallsParallel
    else
        execCalls "$@"
    fi
}

# #############################################################################
# Main

prep
gitr "$@"
exit "$?"
