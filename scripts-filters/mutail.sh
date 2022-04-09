#!/usr/bin/env bash

# Info: Tail multiple files.
# Syntax: mutail [-n lines] file1[ file2[ file3 ...]]

typeset first=true
typeset lines=10

typeset oldind="$OPTIND"
OPTIND=1
while getopts ':n:' opt ; do
    case "${opt}" in
        n) lines="${OPTARG}";;
    esac
done
shift $((OPTIND - 1)) ; OPTIND="${oldind}"

for f in "$@" ; do
    ${first} || echo ''

    echo "==> ${f} <==" 1>&2
    tail -n ${lines:-10} "${f}"

    first=false
done

