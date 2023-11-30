#!/bin/bash

mkdir -p /home/${USER}/dockerHome

docker run -ti \
   --net=host \
   -e DISPLAY=${DISPLAY} \
   -v ${HOME}/.Xauthority:/home/${USER}/.Xauthority \
   -v /afs/:/afs \
   -v /etc/localtime:/etc/localtime:ro \
   -v /tools:/tools \
   -v /home:/home/${USER}/dockerHome \
   kek-bpm-rfsoc-model-composer-${USER}:latest /bin/bash

