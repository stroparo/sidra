# Git routines
# Project / License at https://github.com/stroparo/sidra


# Oneliners:
# Check existence to avoid duplicate of alias recipe in dotfiles vs SIDRA Scripting Library:
if ! type gcheckedout >/dev/null 2>&1 ; then function gcheckedout () { git branch -v "$@" | egrep '^(==|[*]|---)' ; } ; fi
if ! type gitbranchactive >/dev/null 2>&1 ; then function gitbranchactive () { echo "$(git branch 2>/dev/null | grep -e '\* ' | sed 's/^..\(.*\)/\1/')" ; } ; fi
if ! type gdd   >/dev/null 2>&1 ; then function gdd () { git add -A "$@" ; git status -s ; } ; fi
if ! type gddd  >/dev/null 2>&1 ; then function gddd () { git add -A "$@" ; git status -s ; git diff --cached ; } ; fi
if ! type gee   >/dev/null 2>&1 ; then function gee () { git add -A "$@" ; git status -s ; git diff --ignore-space-at-eol --cached ; } ; fi
if ! type glsd  >/dev/null 2>&1 ; then function glsd () { git ls-files --deleted ; } ; fi


clonegits () {
  # Info: Clone repos passed in the argument, one per line (quote it).
  # Syntax: {repositories-one-per-line}

  [ -z "${1}" ] && return

  while read repo repo_path ; do
    [ -z "${repo}" ] && continue
    [ -z "${repo_path}" ] && repo_path="$(basename "${repo%.git}")"

    if [ ! -d "$repo_path" ] ; then
      if ! git clone "$repo" "$repo_path" ; then
        echo "clonegits: ERROR: Cloning '$repo' repository to '${repo_path}/'." 1>&2
      fi
    else
      echo "clonegits: SKIP: '$repo_path' repository already exists." 1>&2
    fi

    echo '' 1>&2
  done <<EOF
${1}
EOF
}


clonemygits () {
  typeset devdir="${DEV:-$HOME/workspace}"
  typeset mygits

  # Options:
  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':d:' option ; do
    case "${option}" in
      d) devdir="${OPTARG}";;
    esac
  done
  shift $((OPTIND-1)) ; OPTIND="${oldind}"

  if [ -n "$1" ] ; then
    mygits="$*"
  else
    mygits="$MYGITS"
  fi
  if [ -z "$mygits" ] ; then
    echo "clonemygits: SKIP: no Git repos in MYGITS or args." 1>&2
    return
  fi

  if [ -d "${devdir}" ] ; then
    # Using the clonegits function from SIDRA Scripting Library:
    (cd "${devdir}" \
      && [ "$(basename "$(pwd)")" = "$(basename "$devdir")" ] \
      && clonegits "$mygits")
  fi
}


confgits () {
  for repo in "$@" ; do
    [ -d "$repo/.git" ] || continue
    touch "$repo/.git/config"
    gitset -e "$MYEMAIL" -n "$MYSIGN" -r -v -f "$repo/.git/config"
  done
}


gitbranchtrackall () {
  # Did not use git branch -r because of this:
  # https://stackoverflow.com/questions/379081/track-all-remote-git-branches-as-local-branches

  for i in `git branch -a | grep remotes/ | grep -v HEAD | grep -v master` ; do
    git branch --track "${i#remotes/origin/}" "$i"
  done
}


gitenforcemyuser () {
  [ -n "$MYEMAIL" ] && git config --global --replace-all user.email "$MYEMAIL"
  [ -n "$MYSIGN" ] && git config --global --replace-all user.name "$MYSIGN"
}


gitpull () {

  typeset branch=master
  typeset header_msg="Started"
  typeset remote=origin
  typeset PROGNAME="gitpull()"
  typeset repo

  # Options:
  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':b:h:r:' option ; do
    case "${option}" in
      b) branch="${OPTARG:-master}";;
      h) header_msg="${OPTARG:-master}";;
      r) remote="${OPTARG:-master}";;
    esac
  done
  shift $((OPTIND-1)) ; OPTIND="${oldind}"

  : ${header_msg:=git repositories starting with '$1'}

  if [ $# -eq 0 ] ; then
    gitpull -b "${branch}" -h "${header_msg}" -r "${remote}" "${PWD}"
    return
  fi

  echo
  echo
  echo '###############################################################################'
  echo "${PROGNAME:+$PROGNAME: }INFO: ==> ${header_msg}"
  echo "${PROGNAME:+$PROGNAME: }INFO: ... Args:"
  realpath "$@" | sed -e 's# /#\n/#g' | sed -e 's#/[.]git$##'
  echo '###############################################################################'

  for repo in "$@" ; do
    repo=${repo%/.git}

    if [ ! -d "${repo}/.git" ] ; then
      for repo_found in $(find "$(realpath "${repo}")" -type d -name .git) ; do
        gitpull -b "${branch}" -h "${header_msg}" -r "${remote}" "${repo_found}"
      done
      continue
    fi

    echo
    echo
    echo "${PROGNAME:+$PROGNAME: }INFO: ||"
    if [ -e "${repo}/.git/refs/remotes/${remote}/${branch}" ] ; then
      echo "${PROGNAME:+$PROGNAME: }INFO: ==> Pulling '${repo}' branch '${branch}' from remote '${remote}'..."
    else
      echo "${PROGNAME:+$PROGNAME: }SKIP: ==> Repo '${repo}' missing remote/branch '${remote}/${branch}'..."
      continue
    fi

    branch_previously_out="$(cd "${repo}"; gitbranchactive)"
    echo "${PROGNAME:+$PROGNAME: }INFO: ... current branch: ${branch_previously_out}"

    if [ "${branch_previously_out}" != "${branch}" ] ; then
      (cd "${repo}"; git checkout "${branch}" >/dev/null 2>&1)
      if [ "${branch}" != "$(cd "${repo}"; gitbranchactive)" ] ; then
        echo "${PROGNAME:+$PROGNAME: }WARN: ... failed checking out '${branch}'"
        echo '---'
        continue
      fi
    fi

    # git branch --set-upstream-to="${remote}/${branch}" "${branch}"
    if (cd "${repo}"; git pull "${remote}" "${branch}") ; then
      echo "${PROGNAME:+$PROGNAME: }INFO: ... git status at '${repo}':"
      (cd "${repo}"; git status -s)
    fi

    if [ "${branch_previously_out}" != "${branch}" ] ; then
      (cd "${repo}"; git checkout "${branch_previously_out}" >/dev/null 2>&1)
      if [ "${branch_previously_out}" = "$(cd "${repo}"; gitbranchactive)" ] ; then
        echo "${PROGNAME:+$PROGNAME: }INFO: ... checked out previous branch '${branch_previously_out}'"
      else
        echo "${PROGNAME:+$PROGNAME: }WARN: ... failed checking out previous branch '${branch_previously_out}'." 1>&2
      fi
    fi

    echo '---'
  done
}


gitremotepatternreplace () {
  typeset usage="[-b {branches-to-track-comma-separated}] [-r {remote_name:=origin}] {sed-pattern} {replacement} {repo paths}"

  typeset branches_to_track="master develop"
  typeset remote_name="origin"

  typeset pattern
  typeset replace

  typeset tracksetup=false
  typeset verbose=false

  # Options:
  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':b:hr:stv' option ; do
    case "${option}" in
      b)
        branches_to_track="${OPTARG:-$branches_to_track}"
        if [ -n "$OPTARG" ] ; then
          branches_to_track="$(echo "$branches_to_track" | tr -s ',' ' ')"
        fi
        ;;
      h) echo "$usage" ; return;;
      r) remote_name="${OPTARG}";;
      s) post_sync=true;;
      t) tracksetup=true;;
      v) verbose=true;;
    esac
  done
  shift $((OPTIND-1)) ; OPTIND="${oldind}"

  pattern="$1"
  replace="$2"
  shift 2

  for repo in "$@" ; do
    repo="${repo%/.git}"
    if ! (cd "${repo}" ; git remote -v | grep -q "^ *${remote_name}") ; then
      continue
    fi
    (
      repo="${repo%/.git}"
      cd "${repo}"

      old_remote_value="$(git remote -v | grep "^ *${remote_name}" | head -1 | awk '{print $2;}')"
      new_remote_value="$(echo "${old_remote_value}" | sed -e "s#${pattern}#${replace}#")"

      if [ "${old_remote_value}" != "${new_remote_value}" ] ; then
        echo
        echo "==> Repo: '${repo}'"
        echo "Old '$remote_name' remote: ${old_remote_value}"
        echo "New '$remote_name' remote: ${new_remote_value}"
        git remote remove "${remote_name}"
        git remote add "${remote_name}" "${new_remote_value}"

        if ${tracksetup} ; then
          for branch_to_track in $(echo "${branches_to_track}" | sed -e 's/,/ /g'); do
            gittrackremotebranches -r "${remote_name}" "${PWD}" "${branch_to_track}"
          done
        fi
      elif ${verbose} ; then
        echo
        echo "==> Repo: '${repo}' remote '${remote_name}' URL intact as '$(git remote get-url "${remote_name}")'"
      fi
    )
  done
}


gitset () {
  # Info: Configure git.
  # Syn: [-e email] [-n name] [-f file] [-r] 'key1 value1'[ key2 value2[ ...]]
  # Example: gitset -e "john@doe.com" -n "John Doe" 'core.autocrlf false' 'push.default simple'

  typeset email name replace gitconfigfile
  typeset verbose=false

  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':e:f:n:rv' opt ; do
    case "${opt}" in
    e) email="${OPTARG}" ;;
    f) gitconfigfile="${OPTARG}" ;;
    n) name="${OPTARG}" ;;
    r) replace="--replace-all";;
    v) verbose=true;;
    esac
  done
  shift $((OPTIND-1)) ; OPTIND="${oldind}"

  if [ -n "$gitconfigfile" ]; then
    if [ ! -w "${gitconfigfile}" ] ; then
      echo "FATAL: Must pass writeable file to -f option." 1>&2
      return 1
    else
      gitconfigfile="-f${gitconfigfile}"
    fi
  else
    gitconfigfile='--global'
  fi

  if [ -n "$email" ] ; then
    $verbose && echo "==>" git config $replace $gitconfigfile "user.email" "$email" 1>&2
    git config $replace $gitconfigfile user.email "$email"
    $verbose && echo "\$?=$?"
    $verbose && echo '---'
  fi

  if [ -n "$name" ]  ; then
    $verbose && echo "==>" git config $replace $gitconfigfile "user.name" "$name" 1>&2
    git config $replace $gitconfigfile user.name "$name"
    $verbose && echo "\$?=$?"
    $verbose && echo '---'
  fi

  while [ $# -ge 2 ] ; do
    $verbose && echo "==>" git config $replace $gitconfigfile "$1" "$2" 1>&2
    git config $replace $gitconfigfile "$1" "$2"
    $verbose && echo "\$?=$?"
    $verbose && echo '---'
    shift 2
  done
}


gittrackremotebranches () {
  typeset progname='gittrackremotebranches()'
  typeset usage="[-r {remote_name:=origin}] {repo_path} {branch1[ branch2[ ...]]}"

  typeset remote_name=origin
  typeset repo_path="${PWD%/.git}"
  typeset remote_already_tracked

  # Options:
  typeset oldind="${OPTIND}"
  OPTIND=1
  while getopts ':hr:' option ; do
    case "${option}" in
      h) echo "$usage" ; return;;
      r) remote_name="${OPTARG}";;
    esac
  done
  shift $((OPTIND-1)) ; OPTIND="${oldind}"

  if [ $# -lt 2 ] ; then
    echo "${progname:+$progname: }FATAL: missed valid usage: ${usage}" 1>&2
  fi

  if [ -d "${1%/.git}/.git" ] ; then
    repo_path="${1%/.git}"
  else
    echo "${progname:+$progname: }WARN: No repository directory '${1}' (1st arg.), falling back to default '${repo_path}'." 1>&2
    # TODO code for user to confirm: 'Do you wish to proceed with that default diretory?'
  fi
  shift

  if [ ! -d "${repo_path}/.git" ] ; then
    echo "${progname:+$progname: }FATAL: No repository in directory '${repo_path}'." 1>&2
    return 1
  fi

  (
    cd "${repo_path}"
    if [ "$(basename "${PWD}")" = "$(basename ${repo_path})" ] ; then
      echo
      echo "${progname:+$progname: }INFO: ==> Repo '${repo_path}' started; Target remote: '${remote_name}'..." 1>&2
      for branch_to_track in "$@" ; do
        
        unset remote_already_tracked
        remote_already_tracked="$(git config --local "branch.${branch_to_track}.remote")"
        if [ -n "${remote_already_tracked}" ] ; then
          echo "${progname:+$progname: }INFO: Branch '${branch_to_track}' tracking remote '${remote_already_tracked}' already (target: '${remote_name}')." 1>&2
          # TODO code for user to confirm: 'Do you wish to proceed and override with the new remote '${remote_name}'?'
          continue
        fi
        
        # "Local remote" branch check:
        if [ ! -e "${repo_path}/.git/refs/remotes/${remote_name}/${branch_to_track}" ] ; then
          echo "${progname:+$progname: }WARN: Branch '${branch_to_track}' missing for remote '${remote_name}'. Trying to fetch it..." 1>&2
          git fetch "${remote_name}" "${branch_to_track}"
          if [ ! -e "${repo_path}/.git/refs/remotes/${remote_name}/${branch_to_track}" ] ; then
            echo "${progname:+$progname: }SKIP: Branch '${branch_to_track}' could not be fetched for remote '${remote_name}'." 1>&2
            continue
          fi
        fi

        # Local branch check:
        if [ ! -e "${repo_path}/.git/refs/heads/${branch_to_track}" ] ; then
          git checkout "${branch_to_track}"  # Git will create the local one if not present already.
          if [ ! -e "${repo_path}/.git/refs/heads/${branch_to_track}" ] ; then
            echo "${progname:+$progname: }SKIP: Local branch '${branch_to_track}' unavailable, even after trying to create it." 1>&2
            continue
          fi
        fi

        if git branch --set-upstream-to="${remote_name}/${branch_to_track}" "${branch_to_track}" ; then
          echo "${progname:+$progname: }INFO: Branch '${branch_to_track}' tracking remote '${remote_already_tracked}' now." 1>&2
        fi
      done
    fi
  )
}
