dockeraccess () {
  sudo usermod -aG docker "$USER"
}

dockercleancontainers () {
  docker stop $(docker ps -q) && docker rm $(docker ps -a -q -f status=exited --no-trunc)
}

dockercleanimages () {
  docker rmi $(docker images -q -f dangling=true --no-trunc)
}

dockercleanimagesnone () {
  docker rmi $(docker images -a | grep "none" | awk '/ / { print $3 }')
}

dockercleannetworks () {
  docker network rm $(docker network ls | awk '$3 == "bridge" && $2 != "bridge" { print $1 }')
}

dockercleanvolumes () {
  docker volume rm $(docker volume ls -q -f dangling=true)
}

dockerprune () {
  docker system prune -a
}
