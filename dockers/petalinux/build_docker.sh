#!/bin/bash

docker image build . -t \
	kek-bpm-rfsoc-petalinux-${USER}:latest \
	--build-arg user=${USER} \
	--build-arg uid="$(id -u)" \
	--build-arg gid="$(id -g)"
