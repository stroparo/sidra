installpkgs () {
  typeset subcommand="install"
  typeset timestamp="$(date '+%Y%m%d-%OH%OM%OS')"

  if [[ $INSTPROG = pacman ]] ; then
    subcommand="-S"
  fi

  echo "${PROGNAME:-installpkgs()}: INFO: Installing packages:"
  echo "$@" | sed -e 's/ /\n/g'
  echo sudo "${INSTPROG}" "${subcommand}" "$@"
  if ! (sudo "${INSTPROG}" "${subcommand}" "$@" 2>&1 | tee "/tmp/pkg-install-${timestamp}.log") ; then
    echo "${PROGNAME:-installpkgs()}: WARN: There was an error installing packages - see '/tmp/pkg-install-${timestamp}.log'." 1>&2
  fi
}


installpkgsepel () {
  if ! _is_el_family ; then return ; fi

  typeset timestamp="$(date '+%Y%m%d-%OH%OM%OS')"

  echo "${PROGNAME:-installpkgsepel()}: INFO: Installing EPEL packages..."
  if ! (sudo "${INSTPROG}" install --enablerepo=epel "$@" 2>&1 | tee "/tmp/pkg-install-epel-${timestamp}.log") ; then
    echo "${PROGNAME:-installpkgsepel()}: WARN: There was an error installing packages - see '/tmp/pkg-install-epel-${timestamp}.log'." 1>&2
  fi
}


installrepoepel () {
  # Package indexing setup
  sudo yum makecache fast

  if ! _is_fedora ; then
    echo "PROGNAME: INFO: EPEL - Extra Packages for Enterprise Linux..." # https://fedoraproject.org/wiki/EPEL
    if _is_el7 ; then
      installpkgs https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    else
      installpkgs epel-release.noarch
    fi
  fi
}


validpkgshelper () {
  typeset pkg_list_filename="${1}"
  typeset pkg_list="$(sed -e 's/ *#.*$//' "${pkg_list_filename}" | tr '\n' ' ')"
  typeset cmd="${2}"

  for pkg in $(echo ${pkg_list}) ; do
    if $(echo ${cmd}) "${pkg}" >/dev/null 2>&1 ; then
      echo "${pkg}"
    fi
  done \
  | tr -s '\n' ' '
}


validpkgsapt () {
  typeset pkg_list_filename="${1}"
  typeset cmd="apt-cache show"
  validpkgshelper "${pkg_list_filename}" "${cmd}"
}


validpkgspacman () {
  typeset pkg_list_filename="${1}"
  typeset cmd="pacman -Si"
  validpkgshelper "${pkg_list_filename}" "${cmd}"
}


validpkgsrpm () {
  typeset pkg_list_filename="${1}"
  typeset cmd="yum info"
  validpkgshelper "${pkg_list_filename}" "${cmd}"
}


validpkgs () {
  if _is_arch_family ; then
    validpkgspacman "$@"
  elif _is_debian_family ; then
    validpkgsapt "$@"
  elif _is_el_family ; then
    validpkgsrpm "$@"
  fi
}
