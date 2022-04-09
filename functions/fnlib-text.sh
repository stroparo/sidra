# Project / License at https://github.com/stroparo/sidra

# #############################################################################
# Text processing routines

# Oneliners
catnum () { mutail -n1 "$@" | grep '^[0-9][0-9]*$' ; } # TODO rename to tailnum

# Case conversion
lowerecho () { echo "$@" | tr '[[:upper:]]' '[[:lower:]]' ; }
upperecho () { echo "$@" | tr '[[:lower:]]' '[[:upper:]]' ; }
lowertr () { tr '[[:upper:]]' '[[:lower:]]' ; }
uppertr () { tr '[[:lower:]]' '[[:upper:]]' ; }
lowervar () { eval "$1=\"\$(echo \"\$$1\" | tr '[[:upper:]]' '[[:lower:]]')\"" ; }
uppervar () { eval "$1=\"\$(echo \"\$$1\" | tr '[[:lower:]]' '[[:upper:]]')\"" ; }

ckeof () {
    # Info: Check whether final EOL (end-of-line) is missing.
    # Syntax: [file-or-dir1 [file-or-dir2...]]

    typeset enforcecwd="${1:-.}" ; shift
    typeset files

    for i in "${enforcecwd}" "$@"; do
        if [ -d "$i" ] ; then
            files=$(find "$i" -type f)
        else
            files="${i}"
        fi

        while read file ; do
            #if (tail -n 1 "$i"; echo '##EOF##') | grep -q '.##EOF##$' ; then
            if [ "$(awk 'END{print FNR;}' "${file}")" != \
                "$(wc -l "${file}" | awk '{print $1}')" ]
            then
                echo "${file}"
            fi
        done <<EOF
${files}
EOF
    done
}

ckeolwin () {
    # Info: Check whether any file has windows end-of-line.
    # Syntax: [file-or-dir1 [file-or-dir2...]]

    typeset enforcecwd
    typeset files
    typeset findname
    typeset wccrlf
    typeset wclf

    # Options:
    typeset oldind="${OPTIND}"
    OPTIND=1
    while getopts ':n:' option ; do
      case "${option}" in
        n) findname="${OPTARG}";;
      esac
    done
    shift $((OPTIND-1)) ; OPTIND="${oldind}"

    enforcecwd="${1:-.}"
    shift

    for i in "${enforcecwd}" "$@"; do
        if [ -d "$i" ] ; then
            files="$(find "$i" -type f ${findname:+-name "*${findname}*"})"
        else
            files="${i}"
        fi

        while read file ; do
            #if (tail -n 1 "$i"; echo '##EOF##') | grep -q '.##EOF##$' ; then

            echo "==> '${file}'"

            wccrlf="$(tr '\r' '\n' < "${file}" | wc -l | awk '{print $1;}')"
            wclf="$(wc -l "${file}" | awk '{print $1;}')"
            if [ "${wccrlf:-0}" -gt "${wclf:-0}" ] ; then
                echo "    has at least one CRLF sequence ie is Windows type"
            fi
        done <<EOF
${files}
EOF
    done
}

dos2unix () {
    # Info: Remove CR Windows end-of-line (0x0d) from file.
    # Syntax: [file1 [file2...]]

    if [[ $(which dos2unix) = */bin/* ]] ; then
        command dos2unix "$@"
        return
    fi

    for i in "$@" ; do
        echo "Deleting CR chars from '${i}' (temp '${i}.u').."
        tr -d '\r' < "${i}" > "${i}.u"
        mv "${i}.u" "${i}"
    done
}

echogrep () {
    # Info: Grep echoed arguments instead of files.

    typeset re text
    typeset iopt qopt vopt

    typeset oldind="$OPTIND"
    OPTIND=1
    while getopts ':iqv' opt ; do
        case "${opt}" in
        i) iopt='-i';;
        q) qopt='-q';;
        v) vopt='-v';;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    re="$1" ; shift
    if [ $# -eq 0 ] ; then return ; fi

    # Beware that subst commands might not append newlines
    #  to the variable if echoing nothing ie if an arg
    #  is empty it will not be added to the text
    #  variable as an empty line - CAUTION HERE
    text="$(for i in "$@" ; do echo "${i}" ; done)"

    egrep ${iopt} ${qopt} ${vopt} "$re" <<EOF
${text}
EOF
}

fixeof () {
    # Info: Fix by adding final EOL (end-of-line) when missing.
    # Syntax: [file-or-dir1 [file-or-dir2...]]

    [ "${1}" = '-v' ] && verbose=true && shift
    typeset enforcecwd="${1:-.}" ; shift
    typeset files

    for i in "${enforcecwd}" "$@"; do
        if [ -d "${i}" ] ; then
            files=$(find "${i}" -type f)
        else
            files="${i}"
        fi

        while read file ; do
            #if (tail -n 1 "$i"; echo '##EOF##') | grep -q '.##EOF##$' ; then
            if [ "$(awk 'END{print FNR;}' "${file}")" != \
                "$(wc -l "${file}" | awk '{print $1}')" ]
            then
                echo -e '\n\c' >> "${file}"

                if ${verbose:-false} ; then
                    echo "${file}"
                fi
            fi
        done <<EOF
${files}
EOF
    done
}

getsection () {
    # Info: Picks an (old format) ini section from a file.

    typeset sectionsearch="$1"
    typeset filename="$2"

    awk '
    # Find the entry:
    /^ *\['"${sectionsearch}"'\] *$/ { found = 1; }

    # Print entry content:
    found && $0 ~ /^ *[^[#]/ { inbody = 1; print; }

    # Stop on next entry after printing:
    inbody && $0 ~ /^ *\[/ { exit 0; }
    ' "${filename}"
}

getsectionname () {
    # Info: Exact match for the section name as the getsection function.
    #       Prints only the matching name, good as a reference for when
    #       a regex was passed to a getsection call, to know exactly which
    #       section was retrieved.

    typeset sectionname
    typeset sectionsearch="$1"
    typeset filename="$2"

    sectionname="$(awk '
                # Find and print the entry:
                /^ *\['"${sectionsearch}"'\] *$/ { found = 1; print $0; exit 0; }
                ' \
                "${filename}")"

    if [ -n "$sectionname" ] ; then
        sectionname=$(echo "$sectionname" | sed -e 's/ *[[]//' -e 's/[]] *$//')
        echo "${sectionname}"
    fi
}

