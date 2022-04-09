cpdirtodir () {
  # Usage: srcdir destdir [new basename for the copied dir, placed INSIDE the destdir]
  if [ -d "${1}" ] && [ -d "${2}" ] ; then
    if [ -n "${3}" ] ; then
      if [ -d "$2/$3" ] ; then
        cp -f -v -R  "${1}"/*  "${2%/}/${3%/}/"
      else
        cp -f -v -R  "${1}"    "${2%/}/${3}"
      fi
    else
      cp -f -v -R  "${1}"  "${2%/}/"
    fi
  fi
}
