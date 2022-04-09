#!/usr/bin/env bash

# Purpose:
# This script sorts all words in the file and puts
# them in the second filename one per line.

usage="$(basename "$0") {source-file} {destination-file}"

# #############################################################################
# Functions

sortwords () {
    awk '
    BEGIN {
        FS="[|,;.: \r\t\n]+";
        RS="";
        ORS="";
    }
    {
        for (x = 1; x <= NF; x++) {
            print $x"\n";
            x++;
        }
    }' "${1}" \
    | sort \
    > "${2}" \
    || return 1
}

# #############################################################################
# Main

# Option processing:
if [ -z "${1}" -o -z "${2}" ]; then
  echo "${usage}"
  exit 1
fi

sortwords "${1}" "${2}"
exit "$?"
