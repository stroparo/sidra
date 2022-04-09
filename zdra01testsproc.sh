_is_job_active () { test 0 -lt "$(ps -ef | grep -w "$1" | grep -v grep | wc -l)" ; }
_is_job_inactive () { test 0 -eq "$(ps -ef | grep -w "$1" | grep -v grep | wc -l)" ; }
