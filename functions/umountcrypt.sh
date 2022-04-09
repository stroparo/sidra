# Unmount encrypted partition.

umountcrypt () {
  typeset crypt_prog="${CRYPT_PROG:-veracrypt}"

  if ! which "${crypt_prog}" ; then
    echo "haltsafe: FATAL: No encryption program found, aborting safe halt.."
    return 1
  fi

  if ${crypt_prog:-truecrypt} -t -l ; then
    ${crypt_prog} -d
  fi

  if ! ${crypt_prog:-truecrypt} -t -l >/dev/null 2>&1 ; then
    return 0
  fi
  echo "haltsafe: ERROR: $crypt_prog volumes still mounted." 1>&2
  return 1
}
