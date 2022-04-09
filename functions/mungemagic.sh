mungemagic () {
  # Munge descendant bin* and lib* directories to PATH and library variables.
  # Syn: [-a] [dir1 [dir2 ...]]
  typeset optafter=""
  if [ "$1" = "-a" ] ; then optafter="-a" ; shift ; fi

  for mungeroot in "$@" ; do
    if [ ! -d "$mungeroot" ] ; then continue ; fi

    # Make mungeroot path canonical:
    mungeroot="$(readlink -f "$(cd "${mungeroot}"; echo "$PWD")")"

    if [ -n "${optafter}" ] ; then
      pathmunge ${optafter} -x $(command ls -1d "$mungeroot"/* | egrep -v -w 'bin|lib')
    fi

    pathmunge ${optafter} -x $(echo $(find "$mungeroot" -maxdepth 2 -type d -name bin))
    pathmunge ${optafter} -x -v LIBPATH $(echo $(find "$mungeroot" -maxdepth 2 -type d -name lib))

    # Mirror LIBPATH into LD_LIBRARY_PATH:
    if [ -n "${optafter}" ] ; then
      export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${LIBPATH}"
    else
      pathmunge -x $(command ls -1d "$mungeroot"/* | egrep -v -w 'bin|lib')
      export LD_LIBRARY_PATH="${LIBPATH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
    fi
  done
}
