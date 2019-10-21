#! /usr/bin/env bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1
cwd=`pwd`

USE_PREINST_LIBS=${USE_PREINST_LIBS:-"true"}
if [ $USE_PREINST_LIBS = true ]; then
  export MOD_PATH
  source ../modulefiles/gldas_model.$target             > /dev/null 2>&1
else
  export MOD_PATH=${cwd}/lib/modulefiles
  if [ $target = wcoss_cray ]; then
    source ../modulefiles/gldas_model.${target}_userlib > /dev/null 2>&1
  else
    source ../modulefiles/gldas_model.$target           > /dev/null 2>&1
  fi
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

export target

cd gldas_model.fd/make/MAKDEP
gmake clean
gmake

cd ..
gmake -f Makefile.noah realclean
gmake -f Makefile.noah
gmake -f Makefile.noah install

gmake -f Makefile.noahmp realclean
gmake -f Makefile.noahmp
gmake -f Makefile.noahmp install

exit
