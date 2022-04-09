# This works well with fixing program's startup scripts, but
# will also work generically with anything else as well.
# It will do a timestamped backup every time.

cpfix () {

  # TODO test

  typeset usage="
USAGE
cpfix {fixed-filename} {target-tree-path|target-filename} [target-filename-relative-to-tree=bin/start.bat]

EXAMPLES
cpfix start.bat target/dir bin/start.bat
cpfix start.bat target/dir/bin/start.bat

The 2nd form only works when the file already exists.
"

  typeset filename_fixed="${1}"
  typeset target_tree_path="${2:-${HOME}/opt/dummy_target_tree_path}"
  typeset target_rel_filename="${3:-bin/start.bat}"
  typeset target_filename="${target_tree_path}/${target_rel_filename}"
  typeset target_backup_filename

  if [ ! -f "${filename_fixed}" ] ; then
    echo "${PROGNAME:+$PROGNAME: }INFO: Usage: ${usage}" 1>&2
    echo "${PROGNAME:+$PROGNAME: }FATAL: No fixed file path." 1>&2
    return 1
  fi

  if [ ! -e "${target_tree_path}" ] ; then
    echo "${PROGNAME:+$PROGNAME: }INFO: Usage: ${usage}" 1>&2
    echo "${PROGNAME:+$PROGNAME: }FATAL: No target-tree-path|target-filename (${target_tree_path}) available." 1>&2
    return 1
  fi

  if [ -f "${target_tree_path}" ] ; then
    target_filename="${target_tree_path}"
  fi
  target_backup_filename="${target_filename}.original-$(%Y-%m-%d-%OH-%OM-%OS)"

  cp -f -v "${target_filename}" "${target_backup_filename}"
  if [ ! -f "${target_backup_filename}" ] ; then
    echo "${PROGNAME:+$PROGNAME: }FATAL: Backup failed." 1>&2
    return 1
  fi
  cp -f -v "${filename_fixed}" "${target_filename}"
}
