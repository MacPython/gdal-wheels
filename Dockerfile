FROM quay.io/pypa/manylinux1_x86_64
MAINTAINER Matthew Brett

COPY config.sh build_docker.sh gdal multibuild /io/
RUN bash /io/build_docker.sh
