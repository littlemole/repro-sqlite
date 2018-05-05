# This is a comment
FROM ubuntu:18.04
MAINTAINER me <little.mole@oha7.org>

# std dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential g++ \
libgtest-dev cmake git pkg-config valgrind sudo joe wget \
openssl libssl-dev libevent-dev uuid-dev sqlite3 libsqlite3-dev \
clang libc++-dev libc++abi-dev \
nghttp2 libnghttp2-dev \
libboost-dev libboost-system-dev libcurl4-openssl-dev

ARG CXX=g++
ENV CXX=${CXX}

# compile gtest with given compiler
ADD ./docker/gtest.sh /usr/local/bin/gtest.sh
RUN /usr/local/bin/gtest.sh

ARG BACKEND=libevent
ENV BACKEND=${BACKEND}

ARG BUILDCHAIN=make
ENV BUILDCHAIN=${BUILDCHAIN}

# build dependencies
ADD ./docker/build.sh /usr/local/bin/build.sh
ADD ./docker/install.sh /usr/local/bin/install.sh

RUN /usr/local/bin/install.sh cryptoneat 
RUN /usr/local/bin/install.sh repro 
RUN /usr/local/bin/install.sh prio

# build an install this project
RUN mkdir -p /usr/local/src/repro-sqlite
ADD . /usr/local/src/repro-sqlite

RUN SKIPTESTS=true /usr/local/bin/build.sh repro-sqlite
