##### **Docker Images**



ping docker.io



docker search ubuntu



docker pull ubuntu



docker images --format "table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}" | sort -k3 -h

docker images -q: Show images imange IDs

docker images -a: Show images including intermediate layers

docker images | grep my-ubuntu



docker inspect --format='{{.Created}}' ubuntu:22.04



docker tag ubuntu:22.04 my-ubuntu:production



docker history --no-trunc ubuntu:22.04



docker system df: Check current disk usage

docker image prune: Remove unused images

docker rmi $(docker images -q): Remove all images

docker system prune: Clean up everything unused (images, containers, networks)

docker system prune -a: Aggressive cleanup (remove all unused images, not just dangling ones)







