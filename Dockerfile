FROM quay.io/pypa/manylinux1_x86_64
MAINTAINER Matthew Brett

ADD . /io
RUN bash /io/build_docker.sh
