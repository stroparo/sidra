dlast   () { cd "$(ls -1d */|sort|tail -n 1)" && ls -AFlrt ; }
ups     () { d "${UPS:-$HOME/upstream}" "$@" ; }
upsalt  () { d "${UPS:-$HOME/upstream}_alt" "$@" ; }
v       () { cd "${DEV:-$HOME/workspace}" ; d "$@" ; }
