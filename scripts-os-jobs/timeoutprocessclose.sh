#!/usr/bin/env bash

# Timeout testing whether a process (by pidof command-like expression) is still running.

PROGNAME="timeoutprocessclose.sh"

PROCESS_EXPR="$1"
TIMEOUT=2
TIMEOUT_MAX=12

if [ -z "${PROCESS_EXPR}" ] ; then
  echo "${PROGNAME:+$PROGNAME: }FATAL: Must pass in a process search expression, often the command name.." 1>&2
  exit 1
fi

# Wait for maximum timeout to avoid returning a misleading return value:
sleep "${TIMEOUT}"
passed="${TIMEOUT}"
while pidof "${PROCESS_EXPR}" >/dev/null 2>&1 && [ "${passed}" -lt "${TIMEOUT_MAX}" ] ; do
  sleep "${TIMEOUT}"
  passed=$((passed+TIMEOUT))
done
! pidof "${PROCESS_EXPR}" >/dev/null 2>&1
exit $?
