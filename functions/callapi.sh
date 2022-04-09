callapi () {
  typeset x="$1"; typeset url="$2"; typeset token="$3"
  curl -s -X ${x:-GET} ${token:+-H "PRIVATE-TOKEN: $token"} "$url"
}
