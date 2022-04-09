#!/usr/bin/env bash

for repo in "$@" ; do
  echo "${PROGNAME:+$PROGNAME: }INFO: Enabling '$repo'..." 1>&2
  sudo sed -i -e "s/^enabled=0/enabled=1/" "/etc/yum.repos.d/${repo}.repo"
done

