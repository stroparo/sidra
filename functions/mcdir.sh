mcdir () {
  # Info: Make and check directory.
  # Syntax: {directory}

  typeset dir="${1}"

  mkdir -p "${dir}" 2>/dev/null

  if [ ! -d "${dir}" ] ; then
    echo "FATAL: '$dir' dir unavailable." 1>&2
    return 10
  elif [ ! -w "${dir}" ] ; then
    echo "WARN: '$dir' dir not writable." 1>&2
    return 0
  fi
}
