# Disk usage routines

# Function dubulk - Displays disk usage of filenames read from stdin.
#  Handles massive file lists.
dubulk () {
  xargs -I{} -n 1 -- du -sm -- "{}"
}

# Function dudesc - Displays disk usage of filenames read from stdin.
#  Sorted in descending order.
dudesc () {
  dubulk | sort -rn
}

# Function dufile - Process data formatted from du, from stdin,
#  yielding back just the filenames.
# Remarks: The original sorting order read from stdin is kept.
# Use case #1: pass filenames to another process that
#  must act on a filesize ordered sequence.
dufile () {
  sed -e 's#^[^[:blank:]]*[[:blank:]][[:blank:]]*##'
}

# Function dugt1 - Displays disk usage of filenames read from stdin which are greater than 1MB.
dugt1 () {
  dubulk | sed -n -e '/^[1-9][0-9]*/p'
}

# Function dugt1desc - Displays disk usage of filenames read from stdin which are greater than 1MB.
#  Sorted in descending order.
dugt1desc () {
  dubulk | sed -n -e '/^[1-9][0-9]*/p' | sort -rn
}

# Function dugt10 - Displays disk usage of filenames > 10MBm read from stdin.
#  Sorted in descending order.
dugt10 () {
  dubulk | sed -n -e '/^[1-9][0-9][0-9]*/p'
}

# Function dugt10desc - Displays disk usage of filenames > 10MBm read from stdin.
#  Sorted in descending order.
dugt10desc () {
  dubulk | sed -n -e '/^[1-9][0-9][0-9]*/p' | sort -rn
}
