# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

GEOS_VERSION="${GEOS_VERSION:-3.6.2}"
PROJ_VERSION="${PROJ_VERSION:-4.9.3}"
JASPER_VERSION="${JASPER_VERSION:-1.900.1.uuid}"
GDAL_VERSION="${GDAL_VERSION:-2.2.1}"
SQLITE3_VERSION="${SQLITE3_VERSION:-3200000}"
# Becaue the URL will change with the version
SQLITE3_URL=https://sqlite.org/2017
JSON_C_VERSION="${JSON_C_VERSION:-0.12.1}"
EXPAT_VERSION="${EXPAT_VERSION:-2.2.3}"

# Sleep time for keeping travis build alive
PING_SLEEP=30s

CONFIG_SH_DIR=$(dirname "${BASH_SOURCE[0]}")

function build_geos {
    build_simple geos $GEOS_VERSION http://download.osgeo.org/geos .tar.bz2
}

function build_jasper {
    if [ -e jasper-stamp ]; then return; fi
    fetch_unpack http://download.osgeo.org/gdal/jasper-${JASPER_VERSION}.tar.gz
    (cd jasper-${JASPER_VERSION} \
        && ./configure --disable-debug --enable-shared --prefix=$BUILD_PREFIX \
        && make \
        && make install)
    touch jasper-stamp
}

function build_proj {
    build_simple proj $PROJ_VERSION http://download.osgeo.org/proj
}

function build_sqlite3 {
    build_simple sqlite-autoconf $SQLITE3_VERSION $SQLITE3_URL
}

function build_json_c {
    build_simple json-c $JSON_C_VERSION https://s3.amazonaws.com/json-c_releases/releases
}

function build_expat {
    build_simple expat $EXPAT_VERSION https://downloads.sourceforge.net/project/expat/expat/${EXPAT_VERSION} .tar.bz2
}

function start_pings {
    # Set up a repeating loop to send some output to Travis.  From
    # https://github.com/conda-forge/libgdal-feedstock/blob/master/recipe/build.sh
    # with thanks.
    local ping_sleep="${1:-30s}"
    bash -c "while true; do echo \$(date) - building ...; sleep $ping_sleep; done" &
    PING_LOOP_PID=$!
}


function stop_pings {
    if [ -n "$PING_LOOP_PID" ]; then
        kill $PING_LOOP_PID
    fi
}

function build_gdal {
    if [ -e gdal-stamp ]; then return; fi
    echo "Here"
    build_zlib
    echo "After here"
    build_curl
    build_expat
    build_sqlite3
    build_json_c
    build_geos
    build_jpeg
    build_libpng
    build_jasper
    build_proj
    build_hdf5
    if [ -n "$IS_OSX" ]; then
        local opts="--enable-rpath"
    else
        local opts="--disable-rpath"
    fi
    (cd ${CONFIG_SH_DIR}/gdal \
        && start_pings $PING_SLEEP \
        && ./configure --disable-debug \
        --with-threads \
        --disable-debug \
        --disable-static \
        --without-grass \
        --without-libgrass \
        --without-jpeg12 \
        --with-jasper=$BUILD_PREFIX \
        --with-libtiff=internal \
        --with-jpeg \
        --with-gif \
        --with-png \
        --with-geotiff=internal \
        --with-sqlite3=$BUILD_PREFIX \
        --with-pcraster=internal \
        --with-pcraster=internal \
        --with-pcidsk=internal \
        --with-bsb \
        --with-grib \
        --with-pam \
        --with-geos=$BUILD_PREFIX/bin/geos-config \
        --with-static-proj4=$BUILD_PREFIX \
        --with-expat=$BUILD_PREFIX \
        --with-libjson-c \
        --with-libiconv-prefix=/usr \
        --with-libz \
        --with-curl=curl-config \
        --without-python \
        --prefix=$BUILD_PREFIX \
        $opts \
        && make \
        && make install ;
        stop_pings)
    touch gdal-stamp
}

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    echo "In pre-build"
    build_gdal
}

function build_wheel {
    echo "In build wheel"
    build_pip_wheel gdal/gdal/swig/python
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    (cd ../gdal/autotest && python run_all.py)
}
