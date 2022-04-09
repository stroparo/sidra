zdraplug () {
  for plugin in "$@" ; do
    plugin_basename="${plugin%.git}"
    plugin_basename="${plugin_basename##*/}"

    was_already_installed=false
    if grep -q "${plugin_basename}" "${ZDRA_PLUGINS_INSTALLED_FILE}" ; then
      was_already_installed=true
    fi

    if ! ${was_already_installed} && zdraplugin.sh "${plugin}" ; then
      zdraload
    fi
  done
}
