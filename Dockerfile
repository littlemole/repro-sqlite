# This is a comment
FROM littlemole/devenv_clangpp_make
MAINTAINER me <little.mole@oha7.org>

ARG CXX=g++
ENV CXX=${CXX}

ARG BACKEND=libevent
ENV BACKEND=${BACKEND}

ARG BUILDCHAIN=make
ENV BUILDCHAIN=${BUILDCHAIN}

ARG TS=
ENV TS=${TS}

RUN /usr/local/bin/install.sh repro 
RUN /usr/local/bin/install.sh prio

# build an install this project
RUN mkdir -p /usr/local/src/repro-sqlite
ADD . /usr/local/src/repro-sqlite

RUN SKIPTESTS=true /usr/local/bin/build.sh repro-sqlite
