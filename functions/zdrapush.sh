# Project / License at https://github.com/stroparo/sidra

zdrapush () {
    # Info:
    #   Push SIDRA scripts and source files to envs pointed to by arguments, packed into
    #   an archive whose filename starts with SIDRA directory's basename eg 'zdra.tar.gz'.
    # Option -d new-zdra-home overrides ZDRA_HOME as the default SIDRA directory.

    typeset zdrarchive zdrabase zdradir zdraparent
    typeset zdrarchivedir="$HOME"
    typeset envre
    typeset extension='.tar.gz'
    typeset excludeERE='====@@@@DUMMYEXCLUDE@@@@===='
    typeset oldind="$OPTIND"
    typeset optdirs="${ZDRA_HOME}"

    OPTIND=1
    while getopts ':d:e:x:' opt ; do
        case ${opt} in
        d) optdirs="$OPTARG";;
        e) envre="$OPTARG";;
        x) excludeERE="$OPTARG";;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="$oldind"

    while read zdradir ; do

        if [ -n "${zdradir}" ] && [ ! -d "${zdradir}" -o ! -r "${zdradir}" ] ; then
            echo "FATAL: zdradir='${zdradir}' is not a valid directory." 1>&2
            return 1
        fi

        zdrarchive="${zdrarchivedir}/$(basename "${zdradir}")${extension}"
        zdrabase="$(basename "${zdradir}")"
        zdraparent="$(cd "${zdradir}" && cd .. && echo "$PWD")"

        if [ -z "$zdrabase" -o -z "$zdraparent" ] ; then
            echo "FATAL: Could not obtain dirname and basename of zdradir='${zdradir}'." 1>&2
            return 1
        fi

        tar -C "${zdraparent}" -cf - \
            $(cd "${zdraparent}" && find "${zdrabase}" -type f | egrep -v "/[.]git|$excludeERE") | \
            gzip -c - > "${zdrarchive}"
    done <<EOF
$(echo "$optdirs" | tr -s , '\n')
EOF

    pushl -r -e "$envre" -f "zdr*${extension}" -s "${zdrarchivedir}" "$@"
    res=$?
    ([ "$res" -eq 0 ] && cd "${zdrarchivedir}" && rm -f zdra*"${extension}")
    return ${res:-1}
}

