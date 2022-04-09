export FILEMGR=thunar

if ! which "${FILEMGR}" >/dev/null 2>&1 ; then
  if which nautilus >/dev/null 2>&1 ; then
    export FILEMGR=nautilus
  elif which dolphin >/dev/null 2>&1 ; then
    export FILEMGR=dolphin
  elif which pcmanfm >/dev/null 2>&1 ; then
    export FILEMGR=pcmanfm
  elif which explorer.exe >/dev/null 2>&1 ; then
    export FILEMGR=explorer.exe
  fi
fi
