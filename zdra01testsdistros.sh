# Arch
_is_arch () { egrep -i -q -r 'id[^=]*=arch' /etc/*release ; }
_is_arch_family () { egrep -i -q -r 'id[^=]*=arch|endeavour|manjaro' /etc/*release ; }
_is_eos () { egrep -i -q -r 'endeavour' /etc/*release ; }
_is_manjaro () { egrep -i -q -r 'manjaro' /etc/*release ; }

# Debian
_is_debian_family () { egrep -i -q -r 'debian|ubuntu' /etc/*release ; }
_is_debian () { egrep -i -q -r 'debian' /etc/*release ; }
_is_ubuntu () { egrep -i -q -r 'ubuntu' /etc/*release ; }

# Enterprise / IBM / RedHat
_is_el_family () { egrep -i -q -r '(cent.?os|oracle|red.?hat|enterprise|rhel|fedora)' /etc/*release ; }
_is_el () { egrep -i -q -r '(cent.?os|oracle|red.?hat|enterprise|rhel)' /etc/*release ; }
_is_el6 () { egrep -i -q -r '(cent.?os|oracle|red.?hat|enterprise|rhel).* 6' /etc/*release ; }
_is_el7 () { egrep -i -q -r '(cent.?os|oracle|red.?hat|enterprise|rhel).* 7' /etc/*release ; }
_is_fedora () { egrep -i -q -r 'fedora' /etc/*release ; }
