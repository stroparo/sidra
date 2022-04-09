#!/usr/bin/env bash

# Purpose:
# This script emulates grep with context operations.
# Default context i.e. before and after is 10 lines
# around the matching position.

export USAGE="$(basename "$0") [-a afterlines] [-b beforelines] [-c contextlines]"

# #############################################################################
# Functions

grepc () {
    typeset afterlines
    typeset beforelines
    typeset contextlines=10

    while getopts ':a:b:c:h' opt ; do
        case "${opt}" in
        a) afterlines="${OPTARG}" ;;
        b) beforelines="${OPTARG}" ;;
        c) contextlines="${OPTARG}" ;;
        h) echo "$USAGE" ; return ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND=1

    : ${afterlines:=${contextlines}}
    : ${beforelines:=${contextlines}}

    grep -n "$@" /dev/null | \
    while IFS=: read filename lineno matched ; do
        echo '================================================='
        echo "${filename}:${lineno}:${matched}"

        start=$((lineno - beforelines))
        [ "${start}" -lt 1 ] && start=1

        end=$((lineno + afterlines))

        echo "${start}:${end}"
        sed -n -e "${start},${end}p" "${filename}"

        echo ''
    done
}

# #############################################################################
# Main

grepc "$@"
exit "$?"
