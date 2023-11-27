#!/bin/bash

docker image build . -t kek-bpm-rfsoc-dev-${USER}:latest --build-arg user=${USER} --build-arg uid=$(id -u)
