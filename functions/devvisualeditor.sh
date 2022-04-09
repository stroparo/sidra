vs () {
  # Open the programming editor (command name in the 'VISUAL' global) in the current dir. by default.
  # If any args. specifieds each of these will be a directory to run the editor with (as an argument).

  typeset first="${1:-$PWD}"

  if [ -z "${1}" ] ; then
    echo "vs(): INFO: No first argument so will use PWD='${PWD}' instead for that one..."
  else
    shift
  fi

  if ! which xdotool >/dev/null 2>&1 && which apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install xdotool
  fi

  if ! which xdotool >/dev/null 2>&1 ; then
    "${VISUAL}" "${first}" "$@"
  else
    for vs_dir in "${first}" "$@" ; do
      if [ -z "${vs_dir}" ] ; then continue ; fi
      # Here assuming the editor puts the dir. basename at the window title:
      WINDOW_ID="$(xdotool search --name "$(basename "${vs_dir}").*(atom|subl|//vscode|webstorm)" | head -1)"
      if [ -z "${WINDOW_ID}" ] ; then
        # Here assuming the GUI editor invoked puts itself in background right away:
        "${VISUAL}" "${vs_dir}"
      else
        echo "vs(): SKIP: Window already opened for this dir.'s basename ('$(basename "${vs_dir}")')." 1>&2
      fi
    done
  fi
}
