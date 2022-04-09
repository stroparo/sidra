# User interactive input handling routines

readmyemail () {
  # Info: read user input for the MYEMAIL environment variable.

  if [ -z "${MYEMAIL}" ] ; then
    userinput 'Type in your email'
    export MYEMAIL="${userinput}"

  elif userconfirm "MYEMAIL set to '${MYEMAIL}'. Override?" ; then
    unset MYEMAIL
    readmyemail
  fi
}

readmysign () {
  # Info: read user input for the MYSIGN environment variable.

  if [ -z "${MYSIGN}" ] ; then
    userinput 'Type in your name or sign'
    export MYSIGN="${userinput}"

  elif userconfirm "MYSIGN set to '${MYSIGN}'. Override?" ; then
    unset MYSIGN
    readmysign
  fi
}

userconfirm () {
  # Info: Ask a question and yield success if user responded [yY]*

  typeset confirm
  typeset result=1

  echo ${BASH_VERSION:+-e} "$@" "[y/N] \c"
  read confirm
  if [[ $confirm = [yY]* ]] ; then return 0 ; fi
  return 1
}

userinput () {
  # Info: Read value to variable userinput.

  echo ${BASH_VERSION:+-e} "$@: \c"
  read userinput
}

validinput () {
  # Info: Read value repeatedly until it is valid, then echo it.
  # Syn: {message} {ere-extended-regex}

  typeset msg=$1
  typeset re=$2

  userinput=''

  if [ -z "$re" ] ; then
    echo 'FATAL: empty regex' 1>&2
    return 1
  fi

  while ! (echo "$userinput" | egrep -iq "^${re}\$") ; do
    echo ${BASH_VERSION:+-e} "${1}: \c"
    read userinput
  done
}

