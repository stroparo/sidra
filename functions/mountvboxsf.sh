mountvboxsf () {
    # Info: Mount virtualbox shared folder.
    # Syntax: path-to-dir (sharing will be named as its basename)

    [ -n "${1}" ] || return 1
    [ -d "${1}" ] || sudo mkdir "${1}"

    if sudo mount -t vboxsf -o rw,uid="${USER}",gid="$(id -gn)" "$(basename ${1})" "${1}"
    then
        cd "${1}"
        pwd
        ls -AFl
    fi
}
