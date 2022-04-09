#!/usr/bin/env sh

sudo cat > /proc/sys/vm/drop_caches <<EOF
3
EOF

