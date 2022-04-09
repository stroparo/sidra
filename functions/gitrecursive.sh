# Wrappers for gitr script from https://github.com/stroparo/sidra
# #############################################################################

# Branch
rbranch () { gitr.sh -fv -- branch -avv | egrep -- "^(==|---)|${1}" ; }
rcheckedout () { gitr.sh -fv -- branch "$@" | egrep -- "^(==|---)|^[*]" ; }

radd    ()  { (export GITR_PARALLEL=false ; gitr.sh -f  -- add -A "$@" ; gitr.sh -fv status -s) ; }
rci     ()  { (export GITR_PARALLEL=false ; gitr.sh -fv -- commit -m "'$@'") ; }
rco     ()  { (export GITR_PARALLEL=false ; gitr.sh -fv -- checkout "$@") ; }
rdca    ()  { (export GITR_PARALLEL=false ; gitr.sh -f  -- diff --cached "$@") ; }
rfetch  ()  { gitr.sh -fv -- fetch "$@" ; }
rfetchallprune () { gitr.sh -fv -- fetch --all -p "$@" ; }
rpull   ()  { gitr.sh -fv -- pull "$@" ; }
rpush   ()  { gitr.sh -fv -- push "$@" ; }
rpushmirror () { gitr.sh -fv push mirror ${1:-master} | egrep -v "fatal:|make sure|repository exists|^$" ; }
rss     ()  { gitr.sh -f -- status -s "$@" ; }

# Compound commands
rpushcurrent () { rpush origin HEAD ; rpushmirror HEAD ; rss ; }
rpushmatching () { rpush origin ':' ; rpushmirror ':' ; rss ; }
rpullremotes () {
  rfetch --all origin
  rfetch --all mirror
  rpull origin HEAD
  rpull mirror HEAD
}


# DEV/workspace pulling:
vpull () {
  # Recursively pull in the devel workspace:
  cd "${DEV:-${HOME}/workspace}"
  if (pwd | fgrep -q "${DEV:-${HOME}/workspace}") ; then
    . "${ZDRA_HOME:-${HOME}/.zdra}/functions/gitrecursive.sh"
    rpull
  fi
}


# Shortcuts
rfap () { rfetchallprune "$@" ; }
rp () { rpull "$@" ; }
rpr ()  { rpullremotes "$@" ; }
rpuc () { rpushcurrent "$@" ; }
rpul () { rpull "$@" ; }
rpum () { rpushmatching "$@" ; }
rpus () { rpush "$@" ; }
vfap () { v ; rfetchallprune "$@" ; }
vp () { vpull "$@" ; }
vpr ()  { v ; rpullremotes "$@" ; }
vpuc () { v ; rpushcurrent "$@" ; }
vpul () { vpull "$@" ; }
vpum () { v ; rpushmatching "$@" ; }
vpus () { v ; rpush "$@" ; }
vss  () { v ; rss "$@" ; }
