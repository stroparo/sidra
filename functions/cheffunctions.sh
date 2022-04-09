# Chef support functions

cfbumplog () {

  typeset cookbook_version=$(grep "^ *version " metadata.rb | sed -e 's/"/'"'"'/g' | cut -d"'" -f2)
  typeset message="$1"

  mv -f -v CHANGELOG.md CHANGELOG.md.orig

  tee CHANGELOG.md <<EOF
${cookbook_version}
$(echo "$cookbook_version" | tr '[[:print:]]' '-')
- ${message}

EOF

  cat >> CHANGELOG.md < CHANGELOG.md.orig \
    && rm -f -v CHANGELOG.md.orig
}

cfbumpminor () {

  typeset cookbook_version=$(grep "^ *version " metadata.rb | sed -e 's/"/'"'"'/g' | cut -d"'" -f2)
  typeset minor_version=$(echo "$cookbook_version" | awk -F. '{print $NF;}')

  minor_version=$((minor_version+1))
  sed -i -e "/^version.*/s/[.][0-9]*\(['\"] *\)$/.${minor_version}\\1/" metadata.rb

  if [ -n "$1" ] ; then
    cfbumplog "$@"
  fi
}
