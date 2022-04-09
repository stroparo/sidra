
_up () {
	typeset searchterm="${1}"
	typeset submatch finalmatch
	submatch="$(echo "${PWD%}" | grep -o "^.*${searchterm}")"
	finalmatch="$(echo "${PWD%}" | grep -o "^${submatch:-.*}[^/]*")"
	echo -n "${finalmatch}"
}


up () {
	if [ $# -eq 0 ]; then
		echo "up: INFO: traverses up the current working directory to first match and cds to it"
		echo "up: WARN: You need an argument"
		return
	else
		cd $(_up "$@")
	fi
}

