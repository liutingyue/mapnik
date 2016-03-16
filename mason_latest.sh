#!/usr/bin/env bash

set -eu

MASON_NAME=mapnik
MASON_VERSION=latest
MASON_LIB_FILE=lib/libmapnik-wkt.a

. ${MASON_DIR:-~/.mason}/mason.sh

function mason_load_source {
    export MASON_BUILD_PATH=$(pwd)
}

function mason_compile {
    HERE=$(pwd)
    make install
    # this is to adapt to when mapnik is not installed in MASON_PREFIX
    # originally (to make it easier to publish locally as a stopgap)
    MAPNIK_PREFIX=$(mapnik-config --prefix)
    if [[ $(mapnik-config --prefix) != ${MASON_PREFIX} ]]; then
        mkdir -p ${MASON_PREFIX}/lib
        mkdir -p ${MASON_PREFIX}/include
        mkdir -p ${MASON_PREFIX}/bin
        cp -r ${MAPNIK_PREFIX}/lib/*mapnik* ${MASON_PREFIX}/lib/
        cp -r ${MAPNIK_PREFIX}/include/mapnik ${MASON_PREFIX}/include/
        cp -r ${MAPNIK_PREFIX}/bin/mapnik* ${MASON_PREFIX}/bin/
        cp -r ${MAPNIK_PREFIX}/bin/shapeindex ${MASON_PREFIX}/bin/
    fi
    if [[ $(uname -s) == 'Darwin' ]]; then
        install_name_tool -id @loader_path/libmapnik.dylib ${MASON_PREFIX}"/lib/libmapnik.dylib";
        PLUGINDIR=${MASON_PREFIX}"/lib/mapnik/input/*.input";
        for f in $PLUGINDIR; do
            echo $f;
            echo $(basename $f);
            install_name_tool -id plugins/input/$(basename $f) $f;
            install_name_tool -change "${MAPNIK_PREFIX}/lib/libmapnik.dylib" @loader_path/../../libmapnik.dylib $f;
        done;
    fi;
    python -c "data=open('$MASON_PREFIX/bin/mapnik-config','r').read();open('$MASON_PREFIX/bin/mapnik-config','w').write(data.replace('$HERE','.'))"
    find ${MASON_PREFIX} -name "*.pyc" -exec rm {} \;
}

function mason_cflags {
    ""
}

function mason_ldflags {
    ""
}

function mason_clean {
    echo "Done"
}

mason_run "$@"
