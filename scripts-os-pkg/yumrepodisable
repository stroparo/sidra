#!/usr/bin/env bash

for repo in "$@" ; do
  echo "${PROGNAME:+$PROGNAME: }INFO: Disabling '$repo' (use --enablerepo=$repo) from now on..." 1>&2
  sudo sed -i -e "s/^enabled=1/enabled=0/" "/etc/yum.repos.d/${repo}.repo"
done

