FROM quay.io/pypa/manylinux1_x86_64
MAINTAINER Matthew Brett

COPY config.sh build_docker.sh /io/
COPY gdal /io/gdal/
COPY multibuild /io/multibuild
RUN bash /io/build_docker.sh
