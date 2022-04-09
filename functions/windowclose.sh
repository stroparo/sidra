# TODO add test for GUI env, if false then return


# windowclose args: {process_expr} [window_expr:=process_expr] [close_shortcut:=ctrl+q]
windowclose () {
  typeset process_expr="${1}"
  typeset window_expr="${2:-$1}"
  typeset close_shortcut="${3:-ctrl+q}"

  echo "windowclose: closing '${process_expr}'..."

  if ! which xdotool >/dev/null 2>&1; then
    killall -HUP "${process_expr}"
    timeoutprocessclose.sh "${process_expr}"
    return $?
  fi

  WINDOW_ID="$(xdotool search --name "${window_expr}" | head -1)"
  if [ -z "${WINDOW_ID}" ] ; then
    echo "windowclose(): SKIP: No window found for window expression '${window_expr}'." 1>&2
    return 0
  fi
  xdotool windowactivate --sync "${WINDOW_ID}"
  xdotool key --clearmodifiers "${close_shortcut}"

  timeoutprocessclose.sh "${process_expr}"
  return $?
}
