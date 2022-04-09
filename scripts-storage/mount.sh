#!/usr/bin/env bash

PROGNAME="mount.sh"

_mount () {
  typeset result=0

  for mount_point in "$@" ; do

    if [ ! -d "${mount_point}" ] ; then
      echo "${PROGNAME}: SKIP: No mount point '${mount_point}'." 1>&2
      continue
    fi

    if ! grep -q "${mount_point}" /etc/fstab ; then
      echo "${PROGNAME}: SKIP: Mount point '${mount_point}' not in fstab." 1>&2
      continue
    elif grep -q "${mount_point}" /etc/mtab ; then
      echo "${PROGNAME}: SKIP: Already mounted '${mount_point}'." 1>&2
      continue
    else
      if ! sudo mount "${mount_point}" ; then
        result=1
      fi
    fi
  done

  return ${result}
}

_mount "$@"
