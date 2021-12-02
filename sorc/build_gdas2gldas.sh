#! /usr/bin/env bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

USE_PREINST_LIBS=${USE_PREINST_LIBS:-"true"}
if [ $USE_PREINST_LIBS = true ]; then
  export MOD_PATH
  module purge
  module use ../modulefiles
  module load gdas2gldas.$target             > /dev/null 2>&1
else
  export MOD_PATH=${cwd}/lib/modulefiles
  if [ $target = wcoss_cray ]; then
    module purge
    module use ../modulefiles
    module load gdas2gldas.${target}_userlib > /dev/null 2>&1
  else
    module purge
    module use ../modulefiles
    module load gdas2gldas.$target           > /dev/null 2>&1
  fi
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

#
# --- Chgres part
#
cd gdas2gldas.fd

export FCOMP=ftn
export FFLAGS="-O3 -fp-model precise -g -traceback -r8 -i4 -qopenmp -convert big_endian -assume byterecl"

make clean
make
make install

exit
