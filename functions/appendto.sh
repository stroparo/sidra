appendto () {
    # Info: Append to variable (arg1), the given text (arg2).
    # Todo: Option to replace the default separator which is a newline character.

    if [ -z "$(eval "echo \"\$${1}\"")" ] ; then
        eval "${1}=\"${2}\""
    else
        eval "${1}=\"\$${1}
${2}\""
    fi
}
