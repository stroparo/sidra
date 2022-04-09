# Project / License at https://github.com/stroparo/sidra

# #############################################################################
# Mathematical routines

getmax () {
    # Syn: sep field files...

    typeset sep="${1}"
    typeset field="${2}"
    shift 2

    awk -F"${sep}" -vfield="${field}" '
        BEGIN {
            max = 0;
        }

        {
            if (max < $field) max = $field;
        }

        END {
            print max;
        }
    ' "$@"

}

getmin () {
    # Syn: sep field files...

    typeset sep="${1}"
    typeset field="${2}"
    shift 2

    awk -F"${sep}" -vfield="${field}" '
        BEGIN {
            min = 2147483648;
        }

        {
            if (min > $field) min = $field;
        }

        END {
            print min;
        }
    ' "$@"

}

getsum () {
    # Syn: sep field files...

    typeset sep="${1}"
    typeset field="${2}"
    shift 2

    awk ${sep:+-F$sep} -vfield="${field}" '{ sum += $field; } END { print sum; }' "$@"
}

isinslice () {
    # Info: Tests wether number is in a [min, max) slice.
    # Syn: num min max

    typeset oldind="${OPTIND}"

    OPTIND=1
    while getopts 'h' option ; do
        case "${option}" in
        h|help)
            echo 'Usage: num [min max) (open ended)'
            return
            ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND=1

    if [ "${#}" -ne 3 ] ; then return 1 ; fi

    [[ ${1} -ge ${2} && ${1} -lt ${3} ]]
}

