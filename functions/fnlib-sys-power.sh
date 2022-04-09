haltsafe () {
  cd ~
  if umountcrypt ; then
    sudo shutdown -h now
  else
    return 1
  fi
}

rebootsafe () {
  cd ~
  if umountcrypt ; then
    sudo reboot
  else
    return 1
  fi
}
