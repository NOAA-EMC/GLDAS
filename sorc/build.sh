#!/bin/bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1

if [[ "$target" != "NULL" ]]; then
  moduledir=`dirname $(readlink -f ../modulefiles)`
  set +x
  module use ${moduledir}
  module load gldas.${target}
  module list
  set -x
  INSTALL_PREFIX=${INSTALL_PREFIX:-"../"}
  CMAKE_OPTS+=" -DCMAKE_INSTALL_BINDIR=exec"
fi

[[ -d build  ]] && rm -rf build
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX:-"../"} ${CMAKE_OPTS:-} ..
make -j ${BUILD_JOBS:-4} VERBOSE=${BUILD_VERBOSE:-}
make install
