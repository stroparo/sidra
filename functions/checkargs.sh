checkargs () {
    # Info: Checks number of arguments, closed slice.
    # Syn: {min-args} [max-args=min-args]

    typeset args_slice_min="${1:-0}"
    typeset args_slice_max="${2:-0}"
    shift 2

    if [ "${#}" -lt "${args_slice_min}" -o \
           "${#}" -gt "${args_slice_max}" ] ; then
        echo "Bad arguments:" "$@" 1>&2
        return 1
    fi
}

