#! /usr/bin/env bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

USE_PREINST_LIBS=${USE_PREINST_LIBS:-"true"}
if [ $USE_PREINST_LIBS = true ]; then
  export MOD_PATH
  module reset
  module use ../modulefiles
  module load gldas_rst.$target             > /dev/null 2>&1
else
  export MOD_PATH=${cwd}/lib/modulefiles
  if [ $target = wcoss_cray ]; then
    module reset
    module use ../modulefiles
    module load gldas_rst.${target}_userlib > /dev/null 2>&1
  else
    module reset
    module use ../modulefiles
    module load gldas_rst.$target           > /dev/null 2>&1
  fi
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

cd gldas_rst.fd/noah

export FC=ftn
export FOPTS='-O -FR -I$(NEMSIO_INC) -convert big_endian'

make clean
make
make install

#cd ../noahmp

#make clean
#make
#make install

exit
