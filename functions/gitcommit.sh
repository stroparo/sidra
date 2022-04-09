gci () { typeset msg="$1"; shift; git commit -m "$msg" "$@" ; }
gciadd () { typeset msg="$1"; shift; git commit -m "Add $msg" "$@" ; }
gcicom () { typeset msg="$1"; shift; git commit -m "Comment $msg" "$@" ; }
gcifix () { typeset msg="$1"; shift; git commit -m "Fix $msg" "$@" ; }
gcifmt () { typeset msg="$1"; shift; git commit -m "Format $msg" "$@" ; }
gcimv () { typeset msg="$1"; shift; git commit -m "Move $msg" "$@" ; }
gciorg () { typeset msg="$1"; shift; git commit -m "Organize $msg" "$@" ; }
gcirf () { typeset msg="$1"; shift; git commit -m "Refactor $msg" "$@" ; }
gcirn () { typeset msg="$1"; shift; git commit -m "Rename $msg" "$@" ; }
gcirm  () { typeset msg="$1"; shift; git commit -m "Remove $msg" "$@" ; }
gcitodo () { typeset msg="$1"; shift; git commit -m "TODO $msg" "$@" ; }
gciup () { typeset msg="$1"; shift; git commit -m "Update $msg" "$@" ; }
gciwp () { typeset msg="$1"; shift; git commit -m "Work in progress $msg" "$@" ; }

gpi () { gci "$@" ; gpa ; }
gpicom () { gcicom "$@" ; gpa ; }
gpifix () { gcifix "$@" ; gpa ; }
gpifmt () { gcifmt "$@" ; gpa ; }
gpimv () { gcimv "$@" ; gpa ; }
gpiorg () { gciorg "$@" ; gpa ; }
gpirf () { gcirf "$@" ; gpa ; }
gpirn () { gcirn "$@" ; gpa ; }
gpirm  () { gcirm "$@" ; gpa ; }
gpitodo () { gcitodo "$@" ; gpa ; }
gpiup () { gciup "$@" ; gpa ; }
gpiwp () { gciwp "$@" ; gpa ; }


g1 () {

  typeset message="$1" ; shift

  echo
  echo "Status:"
  git status -s

  echo
  echo "Diff index (staged) vs HEAD ie what is being commited:"
  git diff --ignore-space-at-eol --cached

  echo
  if userconfirm "Commit and push?" ; then

    while [ -z "$message" ]; do
      echo "Enter commit message:"
      read message
    done

    git add -A "$@"

    # If explicit args then ensure all removed files are also staged for removal:
    if [ $# -gt 0 ] && [ ! -z "$*" ] ; then
      git rm $(git ls-files --deleted) 2> /dev/null
    fi

    git commit -m "$message"

    gpa HEAD
    return $?
  fi
}


gpa () {
  # Info: Git push the given branch to all remotes (branch defaults to HEAD)
  # Usage: [branch=HEAD]

  typeset branch="${1:-HEAD}"
  typeset remote
  typeset result=0

  echo
  echo "gpa: INFO: Checking out the '${branch}' branch..."
  if ! git checkout "${branch}" ; then return 1 ; fi

  for remote in $(git remote) ; do
    echo
    echo "gpa: INFO: Pushing to remote '${remote}'s branch '${branch}'..."
    if ! git push "${remote}" "${branch}" ; then
      result=1
    fi
  done
  return $result
}

