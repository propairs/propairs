#!/usr/bin/env bash

# This script documents how to build the singularity container
# from the Dockerfile


# exit on errors
trap 'exit' ERR


# build docker container
docker build -t propairs .

# docker registry server to host docker image locally
# do nothing if running, otherwise try to start registry or create registry
[ $(docker inspect -f '{{.State.Running}}' registry) == "true" ] \
  || docker container start registry \
  || docker run -d -p 5000:5000 --restart=always --name registry registry:2

# push image to local registry
docker tag propairs localhost:5000/propairs
docker push localhost:5000/propairs

# create a temporary singularity def file
declare -r TMPFILE="$(mktemp --suffix 'singularity.def')"
cat > "$TMPFILE" << EOI
Bootstrap: docker
Registry: http://localhost:5000
Namespace:
From: propairs:latest

%post

mkdir /cluster /work /usit /projects /data/
EOI
# build singularity image 
sudo SINGULARITY_NOHTTPS=1 /home/fkrull/usr/bin/singularity build propairs.simg "$TMPFILE"

# remove temp file
rm -f "$TMPFILE"

# stop registry server
docker container stop registry
