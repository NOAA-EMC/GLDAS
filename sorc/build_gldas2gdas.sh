#! /usr/bin/env bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

USE_PREINST_LIBS=${USE_PREINST_LIBS:-"true"}
if [ $USE_PREINST_LIBS = true ]; then
  export MOD_PATH
 if [ $target = wcoss2 ]; then
  module reset
 else
  module purge
 fi
  module use ../modulefiles
  module load gldas2gdas.$target             > /dev/null 2>&1
else
  export MOD_PATH=${cwd}/lib/modulefiles
  if [ $target = wcoss_cray ]; then
    module reset
    module use ../modulefiles
    module load gldas2gdas.${target}_userlib > /dev/null 2>&1
  else
    module reset
    module use ../modulefiles
    module load gldas2gdas.$target           > /dev/null 2>&1
  fi
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

#
# --- Chgres part
#
cd gldas2gdas.fd

if [ $target = wcoss2 ]; then
   export FCOMP=ftn
elif [ $target = wcoss_cray ]; then
   export FCOMP=ftn
elif [ $target = wcoss_dell_p3 ]; then
   export FCOMP=mpif90
else
   export FCOMP=mpiifort
fi
export FFLAGS="-O3 -fp-model precise -g -traceback -r8 -i4 -qopenmp -convert big_endian -assume byterecl"

make clean
make
make install

exit
