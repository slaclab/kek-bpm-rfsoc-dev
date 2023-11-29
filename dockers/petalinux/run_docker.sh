#!/bin/bash

docker run -ti \
   --net=host \
   -e DISPLAY=${DISPLAY} \
   -v ${HOME}/.Xauthority:/home/${USER}/.Xauthority \
   -v /afs/:/afs \
   -v /etc/localtime:/etc/localtime:ro \
   -v /tools:/tools \
   -v /home:/home \
   kek-bpm-rfsoc-petalinux-${USER}:latest /bin/bash

