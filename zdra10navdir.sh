# Directory navigation functions (cd etc.)

cdenforce () {
  mkdir -p "$1"
  cd "$1"
  [[ $PWD = */${1#/} ]]
}
