rmfd () {
  # Truncates file descriptors of processes writing to the files in arguments.
  # If this does not work, truncate the file instead (e.g. with '> filename').

  for expr in "$@" ; do
    pids="$(lsof +L1 | grep "${expr}" | fgrep '(deleted)' | awk '{ print $2; }')"
    for pid in $(echo ${pids}) ; do
      (
        cd /proc/${pid}/fd
        descriptors=$(ls -l | grep "${expr}" | fgrep '(deleted)' | awk '{ print $9; }')
        for descriptor in $(echo ${descriptors}) ; do
          if [ -e ${descriptor} ]; then
            ls -l ${PWD}/${descriptor}
            sudo su -c "> ${PWD}/${descriptor}"
            ls -l ${PWD}/${descriptor}
          fi
        done
      )
    done
  done
}
