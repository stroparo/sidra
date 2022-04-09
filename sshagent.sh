#!/usr/bin/env bash

SSH_ENV="$HOME/.ssh/environment"

_ssh_agent_start () {

    # Make directory if needed:
    [ -d "${SSH_ENV%/*}" ] || mkdir -p "${SSH_ENV%/*}"

    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"

    chmod 600 "$SSH_ENV"
    . "$SSH_ENV" > /dev/null

    ssh-add "$@"
}

_ssh_agent_test () {

    typeset key_added="${1}"
    typeset key_added_basename="$(basename "${1}")"

    ssh-add -l > /dev/null 2>&1

    if [ $? -eq 2 ]; then
        echo 'Failure: Another login session is already using the ssh-agent.' 1>&2
        return 1
    else
        if (ssh-add -l | grep -q "The agent has no identities") \
          || ! (ssh-add -l | grep -q "${key_added_basename}") ; then
            ssh-add "$@"

            # $SSH_AUTH_SOCK broken so we start a new proper agent:
            if [ $? -eq 2 ];then
                _ssh_agent_start "$@"
            fi
        elif [ -n "${_ssh_agent_verbose}" ] ; then
            # Redirect to stderr in case this echoes while loading an environment:
            echo 'SSH agent identities:' 1>&2
            ssh-add -l 1>&2
        fi

    fi
}

_ssh_agent () {

    unset _ssh_agent_verbose

    OPTIND=1
    while getopts ':v' opt ; do
        case "${opt}" in
        v) _ssh_agent_verbose=true ;;
        esac
    done
    shift $((OPTIND-1)); OPTIND=1

    while (echo "$1" | grep -i -q 'sshagent.sh') ; do
    	shift
    done

    if [ -f "$SSH_ENV" ] && [ -r "$SSH_ENV" ]; then
        . "$SSH_ENV" > /dev/null

        if ps -ef | grep "$SSH_AGENT_PID" | grep -v grep | grep -q ssh-agent ; then
            _ssh_agent_test "$@"
        else
            _ssh_agent_start "$@"
        fi
    else
        _ssh_agent_start "$@"
    fi

}

_ssh_agent -v "$@"

