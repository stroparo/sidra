#!/usr/bin/env bash

loop () {
    # Info: Pass a command to be executed every secs seconds.
    # Syn: [-d secs] command

    typeset interval=10

    typeset oldind="$OPTIND"
    OPTIND=1
    while getopts ':d:' opt ; do
        case "${opt}" in
        d)
            interval="${OPTARG}"
            ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    while true ; do
        clear 2>/dev/null || echo '' 1>&2
        echo "Looping thru every ${interval} seconds.." 1>&2
        echo "Command:" "$@" 1>&2
        $@
        sleep "${interval}" 2>/dev/null \
        || sleep 10 \
        || break
    done
}

loop "$@"
