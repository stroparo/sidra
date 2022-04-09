#!/usr/bin/env bash

# Project / License at https://github.com/stroparo/sidra

# #############################################################################
# Globals

export PNAME="$(basename "$0")"
export USAGE="
NAME
    ${PNAME} - push files to target environments using LFTP program

SYNOPSIS
    ${PNAME} [-e {env-regex}] [-f {local-globs}] [-p] [-r] [-s {srcdir}] {site} [site2 [site3 ...]]

DESCRIPTION

    The environment list containing all possible sites lie in ee.txt files
    inside directory trees whose roots are specified by the SIDRA Scripting Library'
    EEPATH environment variable (all this environment logic is in ee.sh).

    -e env-regex

        If and only if env-regex is non-empty, this program will override all site
        arguments, filtering ee.txt lists instead. The regex will be used.

        Remark:

        Directories containing ee.txt lists are the ones specified in the
        EEPATH environment variable.

    -r option
        Reset files, i.e. deletes them from destination before copying.

    -p option
        Causes ${PNAME} to only purge all files in the destination
        Usage of -r is redundant here.
"

export CONN=''
export CONNOPT=''
export ENVPATHS=''
export ENVREGEX=''
export GLOBSFINAL=''
export GLOBSOPT=''
export PURGE_ONLY=false
export RESET_FILES=false

export DESTDIR='~'
export SRCDIR="$(echo "$PWD")"

OPTIND=1
while getopts ':c:d:e:f:hprs:' opt ; do
    case ${opt} in
    h) echo "$USAGE" ; exit ;;
    c) export CONNOPT="${OPTARG}";;
    d) export DESTDIR="${OPTARG}";;
    e) export ENVREGEX="${OPTARG}";;
    f) export GLOBSOPT="${OPTARG}";;
    p) export PURGE_ONLY=true ;;
    r) export RESET_FILES=true ;;
    s) export SRCDIR="${OPTARG}";;
    esac
done
shift $((OPTIND - 1))

# #############################################################################
# Functions

checkEnv () {

    if [ ! -d "$SRCDIR" ] || [ ! -r "$SRCDIR" ] ; then
        echo "$PNAME: FATAL: Dir '$SRCDIR' should be readable."
        exit 1
    fi

    # Check available lftp program:
    if ! which lftp >/dev/null 2>&1 ; then
        echo "FATAL: lftp program not found. Aborted."
        exit 10
    fi

}

sourceds () {

    typeset zdrahome="${1:-${ZDRA_HOME}}"

    if ! . "${zdrahome}/zdra.sh" "${zdrahome}" 1>&2 2>/dev/null || [ -z "${ZDRA_LOADED}" ] ; then
        echo "${PNAME:+${PNAME}: }FATAL: Could not load SIDRA Scripting Library." 1>&2
        return 1
    fi

}

ckeeu () {

    if [ -z "$eeu" ] ; then
        echo "SKIP: env '${envname}' because of empty username (eeu variable)." 1>&2
        return 1
    fi

    return 0
}

ckeeh () {

    if [ -z "$eeh" ] ; then
        echo "SKIP: env '${envname}' because of empty hostname (eeh variable)." 1>&2
        return 1
    fi

    return 0
}

ckglobs () {
    if [[ -z $GLOBSFINAL ]]; then
        echo "FATAL: Empty value in GLOBSFINAL." 1>&2
        exit 1
    fi
}

setglobs () {

    if [[ -n $GLOBSOPT ]] ; then
        export GLOBSVAL="$GLOBSOPT"
    elif [ -z "$1" ] ; then
        echo 'setglobs:INFO: Glob set to "*" as no -f globsopt was passed.' 1>&2
        export GLOBSVAL="*"
    else
        export GLOBSVAL="$1"
    fi

    export GLOBSFINAL="$GLOBSVAL"

    ckglobs
}

pushl () {

    setglobs

    if [ -z "$1" ] ; then
        echo "FATAL: No environments passed to pushl function." 1>&2
        return 1
    fi

    cd "$SRCDIR"

    if [ "$PWD" != "$SRCDIR" ] ; then
        echo "FATAL: Could not cd into SRCDIR='${SRCDIR}'." 1>&2
        return 1
    fi

    while read envname ; do

        if [ "$envname" != nil ] ; then
            if ! eesel "$envname" ; then
                echo "SKIP: env '${envname}' not found." 1>&2
                continue
            fi
        fi

        if ! ckeeu || ! ckeeh ; then
            continue
        fi

        echo "    Files: '${GLOBSFINAL}'" 1>&2

        # Prep path
        CONNROOT="sftp://${eeh}/"
        CONN="sftp://${eeh}/${DESTDIR}"

        echo "    $(${PURGE_ONLY} && echo "(Purge files in) ")Path: '${DESTDIR}'." 1>&2

        if ${PURGE_ONLY} || ${RESET_FILES} ; then
            lftp -u "${eeu},${eepw}" "${CONN}" <<EOF
set sftp:auto-confirm yes ; mrm -f ${GLOBSFINAL}
EOF
        fi
        ${PURGE_ONLY} && continue

        # Put files:
        (
            lftp -u "${eeu},${eepw}" "${CONNROOT}" 2>/dev/null <<EOF
set sftp:auto-confirm yes ; mkdir -p ${DESTDIR} ; cd ${DESTDIR}
EOF
            if [ $? -eq 0 ] ; then
                lftp -u "${eeu},${eepw}" "${CONN}" <<EOF
set sftp:auto-confirm yes ; mput ${GLOBSFINAL}
EOF
            fi
        )

        if [ "$?" != 0 ] ; then
            echo "FATAL: error pushing to '${envname}'." 1>&2
            return 1
        fi
    done <<EOF
${1}
EOF

    echo 'INFO: Pushing process complete.' 1>&2
}

# #############################################################################
# Main

checkEnv
sourceds || exit "$?"

if [ -n "${ENVREGEX}" ] ; then
    envlist="$(eel -e "${ENVREGEX}")"
else
    envlist="$(for envname in "$@" ; do echo "${envname}" ; done)"
fi

pushl "${envlist}"
exit "$?"
