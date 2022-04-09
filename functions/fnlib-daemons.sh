startdropbox () {
  if [ -x ~/.dropbox-dist/dropboxd ] && ! pgrep -fl dropbox ; then
    env DBUS_SESSION_BUS_ADDRESS='' ~/.dropbox-dist/dropboxd & disown
  fi
}
