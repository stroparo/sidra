#!/usr/bin/env bash

PROGNAME="gitremoteaddmirror.sh"

export MIRROR_DIRNAME_URL="${1:-https://bitbucket.org/usuario1n2o3n4eczistente}"
shift

for repo in "$@"
do
  (
    cd "${repo}"
    repo_basename="$(basename "${repo%.git}")"
    mirror_url="$(git remote get-url mirror 2>/dev/null)"
    if [ -z "${mirror_url}" ] ; then
      if git remote add mirror "${MIRROR_DIRNAME_URL%/}/${repo_basename}.git" ; then
        echo ${BASH_VERSION:+-e} "${PROGNAME}: INFO: repo '${repo}' added mirror ==> \c"
        git remote get-url mirror
      fi
    else
      echo "${PROGNAME:+$PROGNAME: }SKIP: repo '${repo}' already has mirror set to '${mirror_url}'." 1>&2
    fi
  )
done
