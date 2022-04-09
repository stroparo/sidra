lstoday () {
  ls -AFlrt | grep "$(date +"%b %d")"
}
