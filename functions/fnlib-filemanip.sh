# File handling routines

# Function archive - backup a set of directories which can also be given as variable names.
# Syntax: [-p prefix] {destination-dir} {src-paths|src-path-variable-names}1+
archive () {
    typeset oldind="$OPTIND"
    typeset bakpath dest src srcident srcpath
    typeset pname=archive
    typeset extension='tgz'
    typeset prefix='bak'
    typeset sep='-'
    typeset timestamp="$(date '+%Y%m%d-%OH%OM%OS')"

    OPTIND=1
    while getopts ':p:z' opt ; do
        case "${opt}" in
        p) prefix="${OPTARG:-${prefix}}" ;;
        z)
            if which zip >/dev/null 2>&1 ; then
                extension=zip
            else
                echo "WARN: zip not available so falling back to tgz." 1>&2
            fi
            ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    [ "$#" -lt 2 ] && echo "FAIL: Min 2 args: destination and sources." 1>&2 && return 10
    dest="${1}"
    shift
    [ ! -d "${dest}" ] && echo "FAIL: Unavailable destination: ${dest}" 1>&2 && return 20

    for src in "$@" ; do

        # Resolving path versus variable indirection:
        if [ -r "${src}" ] ; then
            srcident=$(basename "${src}")
            srcpath="${src}"
        else
            srcident="${src}"
            srcpath="$(eval echo "\$${src}")"

            if [ ! -r "${srcpath}" ] ; then
                echo "SKIP: '${src}' is not a readable path nor a variable (value='${srcpath}')." 1>&2
                continue
            fi
        fi

        bakpath="${dest}/${prefix}${sep}${srcident}${sep}${timestamp}.${extension#.}"

        # Identifying repeated files or variables to be backed up by using indices to tell them apart:
        if [ -e "${bakpath}" ] ; then
            typeset index=1

            while [ -e "${bakpath%.*}-${index}.${extension#.}" ] ; do
                index=$((index + 1))
            done

            bakpath="${bakpath%.*}-${index}.${extension#.}"
        fi

        case "${extension#.}" in
            zip) zip -q -r "${bakpath}" "${srcpath}" ;;
            *)
                tar -cf - -C $(dirname "${srcpath}") $(basename "${srcpath}") \
                | gzip -c - > "${bakpath}"
                ;;
        esac

        if [ "$?" -eq 0 ] ; then
            echo "OK: '${bakpath}' <= '${srcpath}'" 1>&2
        else
            echo "FAIL: '${bakpath}' <= '${srcpath}'" 1>&2
            return 90
        fi
    done
}

# Function childrentgz - archives all srcdir children into destdir/children.tar.gz,
#  via paralleljobs.sh script.
# Deps: dudesc, dufile, paralleljobs.
# Remark: abort if destdir already exists.
# Syntax: [-c gziplevel] [-p maxprocesses] [-u] [-w] srcdir destdir
# Options:
#   -u triggers uncompressed tars
#   -w triggers waiting for the last background process
childrentgz () {
    typeset oldind="$OPTIND"
    typeset srcdir destdir maxprocs paracmd dowait
    typeset gziplevel=1
    typeset uncompressed=false

    OPTIND=1
    while getopts ':c:p:uw' opt ; do
        case "${opt}" in
        c) gziplevel="${OPTARG}";;
        p) maxprocs="${OPTARG}";;
        u) uncompressed=true;;
        w) dowait=true;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    # Checks:

    # Gzip compression:
    if ! ${uncompressed} ; then
        if ! [[ $gziplevel = [1-9] ]] ; then
            echo "FAIL: '$gziplevel' not a valid gzip compression level (must be 1..9)." 1>&2
            return 20
        fi
        echo "INFO: Compression level is ${gziplevel}" 1>&2
    fi

    if [ -e "${2}" ] ; then
        echo "FAIL: Target '${2}' already exists." 1>&2
        return 1
    fi
    mkdir -p "${2}" || return 10

    srcdir="$(cd "${1}"; echo "$PWD")"
    destdir="$(cd "${2}"; echo "$PWD")"

    if [ ! -d "$1" ] || [ ! -r "${srcdir}" ] ; then
        echo "Not a readable source dir ('$1'). Aborted." 1>&2
        return 20
    fi
    if [ ! -d "$2" ] || [ ! -w "${destdir}" ] ; then
        echo "Not a writable destination dir ('$2'). Aborted." 1>&2
        return 30
    fi

    # Main:

    cd "${srcdir}" || return 99

    if ${uncompressed} ; then
        paracmd="tar -cf '${destdir}'/{}.tar {}"
    else
        paracmd="tar -cf - {} | gzip -${gziplevel:-1} -c - > '${destdir}'/{}.tar.gz"
    fi

    echo "INFO: Started." 1>&2
    echo "INFO: Initial delay may ocurr whilst sorting file list by size (desc).." 1>&2
    paralleljobs.sh -l "${destdir}" ${maxprocs:+-p ${maxprocs}} "${paracmd}" <<EOF
$(ls -1 -d * | dudesc | dufile)
EOF
    cd - >/dev/null 2>&1

    if [ -n "$dowait" ] ; then
        wait || return 1
    fi
}

# Function childrentgunz - restores all srcdir/*gz children into destdir,
#  via paralleljobs.sh script.
# Deps: dudesc, dufile, paralleljobs.
# Remark: abort if destdir already exists.
# Syntax: [-p maxprocesses] srcdir destdir
childrentgunz () {
    typeset oldind="$OPTIND"
    typeset srcdir destdir maxprocs
    typeset paracmd="gunzip -c {} | tar -xf -"
    typeset uncompressed=false

    OPTIND=1
    while getopts ':p:u' opt ; do
        case "${opt}" in
        p) maxprocs="${OPTARG}";;
        u) uncompressed=true;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    # Checks:

    if [ -e "${2}" ] ; then
        echo "FAIL: Target '${2}' already exists." 1>&2
        return 1
    fi
    mkdir -p "${2}" || return 10
    srcdir="$(cd "${1}"; echo "$PWD")"
    destdir="$(cd "${2}"; echo "$PWD")"

    [ -r "${srcdir}" ] || return 20
    [ -w "${destdir}" ] || return 30

    if ! ls -1 "${srcdir}"/*.tgz > /dev/null 2>&1 \
    && ! ls -1 "${srcdir}"/*.tar.gz > /dev/null 2>&1 ; then
        echo "WARN: No .tar.gz nor .tgz children to be uncompressed." 1>&2
        return
    fi

    # Main:

    cd "${destdir}" || return 99

    if ${uncompressed} ; then
        paracmd="tar -xf {}"
    fi

    echo "INFO: Started." 1>&2
    echo "INFO: Initial delay may ocurr whilst sorting file list by size (desc).." 1>&2
    paralleljobs.sh -l "${destdir}" ${maxprocs:+-p ${maxprocs}} "${paracmd}" <<EOF
$(ls -1 "${srcdir}"/*.tgz "${srcdir}"/*.tar.gz 2>/dev/null | dudesc | dufile)
EOF
    cd - >/dev/null 2>&1
}

# Function loc - search via locate program.
# Purpose: wrap and interpolate arguments with a literal '*'
#  and execute 'locate -bi {wrapped_args}'. It avoids running
#  locate with just an '*' i.e. you have to pass at least a
#  non-empty argument.
# Syntax: chunk1 [chunk2 ...]
loc () {
  [[ -z ${1} ]] && return 1
  typeset locvalue='*'
  for i in "$@" ; do locvalue="${locvalue}${i}*" ; done
  locate -bi "${locvalue}"
}

# Function renymd - Rename a file by appending Ymd of current date as a suffix.
# Syntax: filenames
renymd () {
    typeset ymdname

    for i in "$@" ; do
        if [ ! -e "${i}" ] ; then
            echo "Skipped abscent file: '${i}'" 1>&2
        else
            ymdname="${i%.*}_$(date '+%Y%m%d').${i##*.}"

            if [ ! -e "${ymdname}" ] ; then
                mv "${i}" "${ymdname}"
            else
                echo "Skipped as already exists: '${ymdname}'" 1>&2
            fi
        fi
    done
}

# Function rentidyedit - rentidy helper.
rentidyedit () {
    echo "${1}" | \
        sed -e 's/\([a-z]\)\([A-Z]\)/\1-\2/g' | \
        tr '[[:upper:]]' '[[:lower:]]' | \
        sed -e 's/[][ ~_@#(),-]\+/-/g' -e "s/['\""'!！'"]//g" | \
        sed -e 's/-[&]-/-and-/g' | \
        sed -e 's/-*[.]-*/./g'
}

# Function rentidy - Renames files and directories recursively at the root given by
#   the argument. Underscores, camel case instances and other special characters are
#   substituted by a hyphen separator.
rentidy () {
    typeset editspace newfilename prefixintact

    if [[ $(sed --version) != *GNU* ]] ; then
        echo "This will only run with GNU sed."
        return 1
    fi

    while read i ; do
        if [[ $i = */* ]] ; then
            prefixintact="${i%/*}"
            editspace="${i##*/}"
        else
            prefixintact=""
            editspace="${i}"
        fi

        newfilename="$(rentidyedit "${editspace}")"
        newfilename="${prefixintact:+${prefixintact}/}${newfilename}"

        if [ "${i}" != "${newfilename}" ] ; then
            if [ ! -e "${newfilename}" ] ; then
                echo "'${i}' -> '${newfilename}'"
                mv "${i}" "${newfilename}"
            else
                echo "SKIP as there is a file for '${newfilename}' already."
            fi
        fi
    done <<EOF
$(find "${1:-.}" -depth)
EOF
}

# Function rm1minus2 - Remove arg1's files that are in arg2 (a set op like A1 = A1 - A2).
# Remark: "<(command)" inline file redirection must be available to your shell.
rm1minus2 () {
    while read i ; do
        [ -d "${1}/$i" ] && echo "Ignored directory '${1}/$i'." 1>&2 && continue
        [ -d "${2}/$i" ] && echo "Ignored directory '${2}/$i'." 1>&2 && continue

        sum1=$(md5sum -b "${1}/$i" | cut -d' ' -f1)
        sum2=$(md5sum -b "${2}/$i" | cut -d' ' -f1)

        if [ "${sum1}" = "${sum2}" ] ; then
            rm "${1}/$i"
        else
            echo "Sums differ, thus ignored '${1}/${i}'." 1>&2
        fi
    done <<EOF
$(ls -1 "${1}" | grep -f <(ls -1 "${2}"))
EOF
}

# Function unarchive - Given a list of archives use the appropriate
#  uncompress command for each. The current directory is the default
#  output directory.
# Syntax: [-o outputdir] [file1[ file2 ...]]
unarchive () {
    typeset oldind="$OPTIND"
    typeset pname=unarchive

    typeset exclude='@@@@DUMMYEXCLUDE@@@@'
    typeset force
    typeset outd='.'
    typeset verbose

    OPTIND=1
    while getopts ':fo:vx:' opt ; do
        case "${opt}" in
        f) force=true;;
        o) outd="${OPTARG:-.}" ;;
        v) verbose=true ;;
        x) exclude="${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    # Check output directory is writable:
    if _any_dir_not_w "${outd}" ; then
        echo "FAIL: '${outd}' must be a writable directory." 1>&2
        return 1
    fi

    for f in "$@" ; do
        export f

        if echo "${f}" | egrep -i -q "${exclude}" ; then
            continue
        fi

        [ -n "${verbose:-}" ] && echo "INFO: Unarchiving '${f}'.." 1>&2

        case "${f}" in

        *.7z)
            ! which 7z >/dev/null 2>&1 && echo "SKIP: '${f}'. 7z program not available." 1>&2 && continue
            7z x -o"${outd}" "${f}"
            ;;

        *.tar.bz2|*tbz2)
            ! which bunzip2 >/dev/null 2>&1 && echo "SKIP: '${f}'. bunzip2 program not available." 1>&2 && continue
            (cd "${outd}" ; bunzip2 -c "${f}" | tar -x${verbose:+v}f -)
            ;;

        *.tar.gz|*tgz)
            (cd "${outd}" ; gunzip -c "${f}" | tar -x${verbose:+v}f -)
            ;;

        *.tar.xz|*txz)
            (cd "${outd}" ; xz -c -d "${f}" | tar -x${verbose:+v}f -)
            ;;

        *.zip)
            ! which unzip >/dev/null 2>&1 && echo "SKIP: '${f}'. unzip program not available." 1>&2 && continue
            unzip "${f}" -d "${outd}"
            ;;

        esac

        if [ "$?" -eq 0 ] && [ -n "${verbose:-}" ] ; then
            echo "OK: '${f}'" 1>&2
        fi
    done
}

# Function xzp - (De)compress set ox xz files, also traverse given dirs looking for xz.
#
# Syntax: [-d] [-t {target root}] filenames...
#
# Options:
# -d
#   Indicates decompression mode. Omitting it yields the default compression mode.
#
# Remark: The target root is going to be a common root for several source directories
#   even when those sources are in separate dir trees in the filesystem all the way up
#   to the root. Also, a target being specified implies xz's -c (--keep).
xzp () {
    typeset cmd copycmd decompress maxprocs target
    typeset compressedfiles files2copy inflatedfiles
    typeset oldind="$OPTIND"

    OPTIND=1
    while getopts ':dp:t:' opt ; do
        case "${opt}" in
        d) decompress='-d' ;;
        p) maxprocs="${OPTARG}" ;;
        t) target="${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1)) ; OPTIND="${oldind}"

    # Set command to place output files to specified target if one was passed in:
    if [ -n "${target}" ] ; then
        if [ ! -d "${target}" -o ! -w "${target}" ] ; then
            echo "FATAL: Target path (${target}) is not writable." 1>&2
            return 1
        fi

        cmd='tgt="'"${target}"'"/{} ; mkdir -p "$(dirname "${tgt}")"'

        copycmd="${cmd}"' ; cp {} "${tgt}"'

        if [ -n "${decompress}" ] ; then
            cmd="${cmd}"' ; xz -c -d {} > "${tgt%.xz}"'
        else # compress
            cmd="${cmd}"' ; xz -c -4 {} > "${tgt}.xz"'
        fi
    else
        cmd="xz ${decompress:--4} {}"
    fi

    # Files:
    compressedfiles=$(eval ls -1dF '"$@"' | grep '[.]xz$')
    inflatedfiles=$(eval ls -1dF '"$@"' | grep -v '[.]xz$' | grep -v '/$')

    # Complement files to be just copied:
    if [ -n "${decompress}" ] ; then
        files2copy="${inflatedfiles}"
    else # compress
        files2copy="${compressedfiles}"
    fi

    # Main action (compress | decompress):
    paralleljobs.sh -p "${maxprocs}" -z xz "${cmd}" <<EOF
${files}
EOF

    # Copy complement files only if a target was specified:
    if [ -n "${target}" ] ; then
        paralleljobs.sh -p "${maxprocs}" "${copycmd}" <<EOF
${files2copy}
EOF
    fi

    # Dirs:
#    for d in "$@" ; do
#        if [ -d "$d" ] ; then
#            cd "${d}"
#            # cat <<EOF
#            paralleljobs.sh -p "${maxprocs}" -z xz "${cmd}" <<EOF
#$(find . -name '*.xz' -type f)
#EOF
#            cd - >/dev/null 2>&1
#        fi
#    done

}

# #############################################################################
