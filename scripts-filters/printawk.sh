#!/usr/bin/env bash

_printawk () {
    typeset fieldsep
    typeset outsep
    typeset pattern
    typeset printargs
    typeset usage="Function printawk - Prints fields as read by awk
Syntax: printawk -F fieldsep -O outsep -p pattern {1st field} [2nd field [3rd ...]]
"
    typeset oldind="${OPTIND}"
    OPTIND=1
    while getopts ':F:hO:p:' opt ; do
        case "${opt}" in
        F) fieldsep="${OPTARG}" ;;
        h) echo "${usage}" ; return ;;
        O) outsep="${OPTARG}" ;;
        p) pattern="${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    for i in "$@" ; do
        printargs="${printargs:+${printargs}, }\$${i}"
    done

    awk ${fieldsep:+-F${fieldsep}} \
        ${outsep:+-vOFS=${outsep}} \
        "${pattern}${pattern:+ }{print ${printargs};}"
}

_printawk "$@"
