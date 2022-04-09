#!/usr/bin/env bash

declare -A remotes

echo "gitreinit: INFO: Current dir '${PWD}'..."

if [ -n "$(find . -mindepth 2 -type d -name .git)" ] ; then
  echo "gitreinit: SKIP: Git (sub?)repos found in current tree, which is not supported."
  return
fi

if ! git status -s >/dev/null 2>&1 ; then
  echo "${PROGNAME:+$PROGNAME: }SKIP: This dir is not inside a git repository." 1>&2
  return
fi

if [ -d ./.git ] ; then
  # Save remotes info:
  for remote in $(git remote) ; do
    remotes[$remote]="$(git remote get-url "$remote")"
  done

  rm -f -r ./.git
  if [ -d ./.git ] ; then
    echo "gitreinit: FATAL: Could not remove ./.git so cannot continue." 1>&2
    return 1
  fi
else
  echo "gitreinit: SKIP: Inside a repo but not at the root."
  return
fi

git init \
  && git add -A -f . \
  && git commit -m 'First commit' \
  || return $?

if [ $? -eq 0 ] ; then
  for remote in "${!remotes[@]}" ; do
    git remote add "$remote" "${remotes[$remote]}"
    git push -f "$remote" master
  done
  if git remote | grep -q origin ; then
    gittrackremotebranches -r origin "$PWD" master
  else
    echo "${PROGNAME:+$PROGNAME: }gitreinit: No remote tracking setup as there is no 'origin' remote." 1>&2
  fi
fi
