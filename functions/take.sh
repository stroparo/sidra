type take >/dev/null 2>&1 && return

take () {
  typeset takendir="$1"
  if [ ! -d "$takendir" ] ; then
    mkdir "$1" || return "$?"
  fi
  cd "$takendir"
}
