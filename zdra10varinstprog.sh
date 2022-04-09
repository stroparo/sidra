export APTPROG=apt-get
export PACPROG=pacman
export RPMPROG=yum
export RPMGROUP="yum groupinstall"

export INSTPROG="$RPMPROG"
if which dnf >/dev/null 2>&1 ; then export RPMPROG=dnf ; export RPMGROUP="dnf group install"; fi
if which "$APTPROG" >/dev/null 2>&1 ; then export INSTPROG="$APTPROG" ; fi
if which "$PACPROG" >/dev/null 2>&1 ; then export INSTPROG="$PACPROG" ; fi
