#!/usr/bin/env bash

# Project / License at https://github.com/stroparo/sidra

# Globals

export PROGNAME="paralleljobs.sh"
export USAGE="
NAME
    ${PROGNAME} - parallel process launcher

SYNOPSIS
    ${PROGNAME} [-q] [-t] [-l {logdir}] ...
    ... [-n {args-per-process}] [-p {maxprocesses}] [-z {taskname}]
    ... {command}

DESCRIPTION
    Call processes in background, producing concurrency effect (or parallelism when
    in a multi-core CPU environment). Each run corresponds to a line of stdin.
    In the command, each instance of the {} character sequence is replaced by
    the corresponding entry and quoted.

OPTIONS
    -l {logdir}
        Defaults to $ZDRA_ENV_LOG
    -q
        Quiet. Do not display informational messages.
    -t
        Tee. Echoes each process log to stdout after all processes have finished.

    -z {CMDZERO, generic taskname to use in the log filename etc.}

        Specify the task name for example when the command starts
        with other stuff in lieu of the command, such as IFS=...
        This is what gets put into the log filename.

EXAMPLES
    gzip {}

"

export HALTSTRING='__HALT__'
export LOGSUFFIXMULTI='psno_'
export TIMESTAMP="$(date '+%Y%m%d%OH%OM%OS')"

# #############################################################################
# Prep args

# Options:

export DOTEE=false
export LOGDIR="${ZDRA_ENV_LOG}"
export MAXPROCS=4
export N=1
export QUIET=false
export SUBSHELL=bash

while getopts ':hl:n:p:qs:tz:' opt ; do
    case "${opt}" in
    h) echo "$USAGE" ; exit ;;
    l) export LOGDIR="${OPTARG}";;
    n) export N="${OPTARG}";;
    p) export MAXPROCS="${OPTARG}";;
    q) export QUIET=true;;
    s) export SUBSHELL="${OPTARG}";;
    t) export DOTEE=true;;
    z) export CMDZERO="${OPTARG}";;
    esac
done
shift $((OPTIND - 1))

# #############################################################################
# Prep

# Prep commands HERE...

# #############################################################################
# Functions

prep () {

    typeset oldpwd="$PWD"

    if ! . "${ZDRA_HOME}/zdra.sh" "${ZDRA_HOME}" >/dev/null 2>&1 || [ -z "${ZDRA_LOADED}" ] ; then
        echo "${PROGNAME}: FATAL: Could not load SIDRA Scripting Library." 1>&2
        exit 1
    fi

    cd "$oldpwd"
}

_paralleljobs () {

    typeset argcount=0
    typeset cmd flatentry iargs icmd ilog ilogsuffix
    typeset logstartline
    typeset logtext
    typeset pcount=0

    cmd="${@} ; res=\$? ; echo \$(date '+%Y%m%d-%OH%OM%OS') ; echo \${res}"
    : ${CMDZERO:=${1%% *}}
    mcdir "${LOGDIR}" || return 10

    # Enforce number type:
    [[ ${MAXPROCS} = [1-9]* ]] || MAXPROCS=4
    [[ ${N} = [1-9]* ]] || N=1

    # Argcount fixed for N==1:
    [ "${N}" -eq 1 ] && argcount=1

    LOGS=()

    while read entry ; do
        [ -z "${entry}" ] && continue

        # Argument list:
        if [ "${N}" -eq 1 ] ; then

            flatentry="$(echo "${entry}" | sed -e 's#/#_#g')"

            ilogsuffix="$(echo "${flatentry}" | \
                sed -e 's/^[^a-zA-Z0-9_ -]*\([a-zA-Z0-9_ -]*\).*$/\1/' \
                    -e 's/ /_/g' \
                    -e 's/__*$//')"

            iargs="'${entry}'"

        elif [ "${N}" -gt 1 ] ; then

            if [ "${argcount}" -eq "${N}" ] ; then
                argcount=0
            fi

            if [ "${entry}" != "${HALTSTRING}" ] ; then
                argcount=$((argcount+1))

                if [ "${argcount}" -eq 1 ] ; then
                    iargs="'${entry}'"
                else
                    iargs="${iargs} '${entry}'"
                fi

                if [ "${argcount}" -lt "${N}" ] ; then
                    continue
                fi
            fi
        else
            $QUIET || echo "FATAL: Invalid -n's argument, must be positive." 1>&2
            return 20
        fi

        # Halting control is best when processing multi-args at a time (n > 1):
        if [ "${entry}" = "${HALTSTRING}" ] ; then
            if [ "${argcount:-0}" -eq 0 ] ; then
                $QUIET || echo "WARN: Halt string found but no arguments pending," 1>&2
                $QUIET || echo "WARN:  ie either the input was empty or the number" 1>&2
                $QUIET || echo "WARN:  of entries was a multiple of n.." 1>&2
                break
            fi

            $QUIET || echo "WARN: Halt string found; calling last job of this set.." 1>&2
        fi

        # Prep command and its log filename:
        iargs="$(echo "${iargs}" | sed 's#&#\\&#g')"
        icmd="$(echo "${cmd}" | sed -e "s#[{][}]#${iargs}#g")" || return 30

        pcount=$((pcount+1))
        if [ "${N}" -gt 1 ] ; then
            ilogsuffix="${LOGSUFFIXMULTI}${pcount}"
        fi

        ilog="$(echo "${LOGDIR}/${CMDZERO}_${TIMESTAMP}_${ilogsuffix}.log" | tr -s '_')"

        if $DOTEE ; then LOGS=(${LOGS[@]} "$ilog") ; fi

        echo "Command: ${icmd}" > "${ilog}" || return 40
        echo "Job output:" >> "${ilog}" || return 40

        # Wait for a vacant pool slot:
        while [ `jobs -r | wc -l` -ge ${MAXPROCS} ] ; do true ; done

        nohup $SUBSHELL -c "${icmd}" >> "${ilog}" 2>&1 &
    done

    if ! $QUIET && [ "${pcount}" -gt 0 ] ; then
        echo "INFO: Finished launching a total of ${pcount} processes for this jobset." 1>&2
        echo "INFO: Processing last batch of `jobs -p | wc -l` jobs.." 1>&2
    fi

    wait || return 1

    if $DOTEE ; then
        for log in ${LOGS[@]} ; do

            logstartline=$(grep -n 'Job output:$' "$log" | cut -d: -f1)
            logstartline=$((logstartline+1))

            logtext="$(awk "NR >= ${logstartline}" "$log")"

            # Omit timestamp and return code when the latter is zero ie success.
            if echo "$logtext" | tail -n 2 | head -n 1 | egrep -q '^.......[0-9]-[0-9].....$' ; then
                if echo "$logtext" | tail -n 1 | egrep -q '^0$' ; then
                    if [[ $(uname) = *[Aa][Ii][Xx]* ]] ; then
                        logtext="$(echo "${logtext}" | tail -r | tail -n +3 | tail -r)"
                    else
                        logtext="$(echo "${logtext}" | head -n -2)"
                    fi
                fi
            fi

            if [ -n "$logtext" ] ; then echo "$logtext" ; echo '---' ; fi
        done
    fi
}

# #############################################################################
# Main

prep
_paralleljobs "$@"
exit "$?"

