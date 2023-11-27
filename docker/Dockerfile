FROM ubuntu:20.04

# Install system tools for model composer
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    locales \
    libtinfo5 \
    python3-pyqt5 \
    xterm \
    libnss3-dev \
    libasound2 \
    libreadline6-dev

# Install system tools for petalinux
RUN DEBIAN_FRONTEND=noninteractive \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    bc \
    gawk \
    net-tools \
    autoconf \
    libtool \
    less \
    rsync \
    texinfo \
    gcc-multilib \
    zlib1g:i386

RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

ARG uid
ARG user
RUN useradd -m -N --gid 0 --shell /bin/bash --uid ${uid} ${user}

RUN mkdir /afs
RUN mkdir /tools

USER ${user}
WORKDIR /home/${user}

