chmodscripts () {
    # Info: Sets mode for scripts inside the specified directories.

    typeset mode='u+rwx'
    typeset verbose

    typeset oldind="$OPTIND"
    OPTIND=1
    while getopts ':m:v' opt ; do
        case "${opt}" in
        m) mode="${OPTARG}" ;;
        v) verbose='-v' ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    chmod ${verbose} "${mode}" $(find "$@" -type f)
}
