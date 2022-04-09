zdraplug () {
  for plugin in "$@" ; do
    plugin_basename="${plugin##*/}"
    plugin_barename="${plugin_basename%.git}"

    was_already_installed=false
    if grep -q "${plugin_barename}" "${ZDRA_PLUGINS_INSTALLED_FILE}" ; then
      was_already_installed=true
    fi

    if ! ${was_already_installed} && zdraplugin.sh "${plugin}" ; then
      zdraload
    fi
  done
}
