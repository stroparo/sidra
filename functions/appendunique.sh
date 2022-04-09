appendunique () {
  # Syntax: [-n] string file1 [file2 ...]
  if [ "$1" = '-n' ] ; then shift ; typeset newline=true; fi
  typeset result=0
  typeset text="${1}" ; shift
  if [ -z "${text}" ] ; then return 0 ; fi
  for f in "$@" ; do
    if [ ! -e "$f" ] ; then echo "WARN: '${f}' does not exist." 1>&2 ; continue ; fi
    if ! grep -F -q "$text" "$f" ; then
      if ${newline:-false} ; then echo '' >> "$f" ; fi
      if ! echo "$text" >> "$f" ; then result=1 ; echo "ERROR: appending '$f'" 1>&2 ; fi
    fi
  done
  return ${result}
}

