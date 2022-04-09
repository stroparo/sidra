#!/usr/bin/env bash

# Globals:
PROGNAME="compresslogs.sh"
MIN_DAYS_DEFAULT=7
MIN_DAYS=${1:-$MIN_DAYS_DEFAULT}
MIN_SIZE_DEFAULT=10
MIN_SIZE=${2:-$MIN_SIZE_DEFAULT}
ROOT_DIR="$PWD"
USAGE="${PROGNAME} [-d {rootdir:=.}] [-h] [min days eligible:=${MIN_DAYS_DEFAULT}] [min size elibible in MB:=${MIN_SIZE_DEFAULT}]"

# Options:
OPTIND=1
while getopts ':d:h' option ; do
  case "${option}" in
    d) ROOT_DIR="${OPTARG}";;
    h) echo "$USAGE"; exit;;
  esac
done
shift "$((OPTIND-1))"

export ROOT_DIR

while read file ; do
  filesize=$(du -sm "$file" | awk '{print $1}')
  if [ ${filesize:-0} -gt ${MIN_SIZE:-${MIN_SIZE_DEFAULT}} ] ; then
    ls -l "$file"
    gzip -v "$file"
  fi
done <<EOF
$(find "${ROOT_DIR}" -type f -mtime +${MIN_DAYS:-${MIN_DAYS_DEFAULT}} -name \*log\* ! -name '*gz')
EOF
