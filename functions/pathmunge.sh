pathmunge () {
    # Info: prepend (-a causes to append) directory to PATH global.
    # Syn: [-v varname] [-x] {path}1+
    # Remark:
    #   -x causes variable to be exported.

    typeset doexport=false
    typeset idempotent=false
    typeset mungeafter=false
    typeset varname=PATH
    typeset mgdpath mgdstring previous

    typeset oldind="${OPTIND}"
    OPTIND=1
    while getopts ':aiv:x' opt ; do
        case "${opt}" in
        a) mungeafter=true;;
        i) idempotent=true;;
        v) varname="${OPTARG}" ;;
        x) doexport=true;;
        esac
    done
    shift $((OPTIND-1)) ; OPTIND="${oldind}"

    for i in "$@" ; do
        mgdpath="$(eval echo "\"${i}\"")"
        previous="$(eval echo '"${'"${varname}"'}"')"

        if ${idempotent:-false} \
          && $(eval echo "\"\$${varname}\"" | grep -F -q -w "${mgdpath}")
        then
          continue
        fi

        if ${mungeafter} ; then
            mgdstring="${previous}${previous:+:}${mgdpath}"
        else
            mgdstring="${mgdpath}${previous:+:}${previous}"
        fi

        eval "${varname}='${mgdstring}'"
    done

    if ${doexport} ; then eval export "${varname}" ; fi
}

